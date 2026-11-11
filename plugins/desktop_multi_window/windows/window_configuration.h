#pragma once

#include <string>
#include <flutter/encodable_value.h>
#include <iostream>

struct WindowConfiguration {
  std::string arguments;
  bool hidden_at_launch = false;

  // Logical pixels. When has_frame is false the default 800x600 is used.
  bool has_frame = false;
  double x = 0;
  double y = 0;
  double width = 800;
  double height = 600;

  bool always_on_top = false;
  bool skip_taskbar = false;
  bool frameless = false;

  static WindowConfiguration FromEncodableMap(
      const flutter::EncodableMap* map) {
    WindowConfiguration config;

    if (!map) return config;

    try {
      auto it = map->find(flutter::EncodableValue("arguments"));
      if (it != map->end()) {
        config.arguments = std::get<std::string>(it->second);
      }

      it = map->find(flutter::EncodableValue("hiddenAtLaunch"));
      if (it != map->end()) {
        config.hidden_at_launch = std::get<bool>(it->second);
      }

      it = map->find(flutter::EncodableValue("frame"));
      if (it != map->end()) {
        const auto* frame = std::get_if<flutter::EncodableList>(&it->second);
        if (frame && frame->size() == 4) {
          config.has_frame = true;
          config.x = std::get<double>((*frame)[0]);
          config.y = std::get<double>((*frame)[1]);
          config.width = std::get<double>((*frame)[2]);
          config.height = std::get<double>((*frame)[3]);
        }
      }

      it = map->find(flutter::EncodableValue("alwaysOnTop"));
      if (it != map->end()) {
        config.always_on_top = std::get<bool>(it->second);
      }

      it = map->find(flutter::EncodableValue("skipTaskbar"));
      if (it != map->end()) {
        config.skip_taskbar = std::get<bool>(it->second);
      }

      it = map->find(flutter::EncodableValue("frameless"));
      if (it != map->end()) {
        config.frameless = std::get<bool>(it->second);
      }
    } catch (const std::exception& e) {
      std::cerr << "Failed to parse WindowConfiguration: " << e.what()
                << std::endl;
    }

    return config;
  }
};
