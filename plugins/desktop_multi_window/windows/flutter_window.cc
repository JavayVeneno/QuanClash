#include "flutter_window.h"

#include "flutter_windows.h"

#include "tchar.h"

#include <iostream>

#include "multi_window_manager.h"
#include "multi_window_plugin_internal.h"

FlutterWindow::FlutterWindow(const std::string& id,
                             const WindowConfiguration config)
    : id_(id), window_argument_(config.arguments) {}

bool FlutterWindow::OnCreate() {
  // Called when the window is created
  RECT frame = GetClientArea();

  flutter::DartProject project(L"data");
  // Avoid Windows fullscreen freezes in recent Flutter engines when
  // window_manager changes styles from a platform-channel call.
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);
  std::vector<std::string> entrypoint_args = {"multi_window", id_,
                                              window_argument_};
  project.set_dart_entrypoint_arguments(entrypoint_args);
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project);

  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    std::cerr << "Failed to setup FlutterViewController." << std::endl;
    return false;
  }

  auto view_handle = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(view_handle);

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  MultiWindowManager::Instance()->RemoveManagedFlutterWindowLater(id_);
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  // Hide the child window (tray panel behaviour) when it loses focus,
  // and notify every engine so the main window can update its state.
  if (message == WM_ACTIVATE) {
    if (LOWORD(wparam) == WA_INACTIVE) {
      if (active_ && ::IsWindowVisible(hwnd)) {
        active_ = false;
        ::ShowWindow(hwnd, SW_HIDE);
        MultiWindowManager::Instance()->NotifyAllWindows("panel_blur");
      }
    } else {
      active_ = true;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

FlutterWindow::~FlutterWindow() {
  // Cleanup is handled by Win32Window::Destroy()
}
