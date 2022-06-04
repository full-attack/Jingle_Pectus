import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Sticker {
  late String img;
  String? sound;
  late String name;
  late String tag;
  List<String> tags = [];

  String? audioCache;

  Future<void> preload() async {
    if (sound == null) return;
    HttpClient httpClient = HttpClient();
    var temp = await getTemporaryDirectory();
    var filePath = '${temp.path}/$tag';
    var file = File(filePath);
    audioCache = filePath;
    if (file.existsSync() && DateTime.now().difference(file.lastAccessedSync()).inMinutes.abs() > 1) return;
    var request = await httpClient.getUrl(Uri.parse(sound!));
    var response = await request.close();
    if(response.statusCode == 200) {
      var bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
    }
  }

  Sticker({required this.img, this.sound, required this.name, required this.tag, List<String>? tags}) {
    this.tags = tags ?? [];
  }

  Sticker.fromJson(Map<String, dynamic> json) {
    img = json['img'];
    sound = json['sound'];
    name = json['name'];
    tag = json['tag'];
    tags = List<String>.from(json['tags'] ?? []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['img'] = this.img;
    data['sound'] = this.sound;
    data['name'] = this.name;
    data['tag'] = this.tag;
    data['tags'] = this.tags;
    return data;
  }
}