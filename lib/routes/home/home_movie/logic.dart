import 'dart:convert' as convert;

import 'package:get/get.dart';
import 'package:movie_flz/config/Global.dart';
import 'package:movie_flz/config/NetTools.dart';

import 'Model/HomeMovieModel.dart';

class HomeMovieLogic extends GetxController {
  final homeMovieInfo = HomeMoveModel().obs;

  int _page_number = 1;
  int course_index = 0;

  //获取用户项目列表
  Future<void> getMovieInfo(
      { //query参数，用于接收分页信息
      refresh = true}) async {
    _page_number = refresh ? 1 : _page_number + 1;
    //换一批
    course_index = refresh ? 0 : course_index;

    var r = await NetTools.dio.get<String>(
      "v3plus/index/channel?pageNum=${_page_number}&position=CHANNEL_INDEX",
    );
    //缓存
    Global.netCache.cache.clear();
    homeMovieInfo.update((val) {
      HomeMoveModel tempModel =
          HomeMoveModel.fromJson(convert.jsonDecode(r.data)['data']);
      if (refresh) {
        val.bean = tempModel.bean;
        val.bannerTop = tempModel.bannerTop;
        val.guessFavorite = tempModel.guessFavorite;
        val.sections = tempModel.sections;
      } else {
        val.sections.addAll(tempModel.sections);
      }
    });
    //json 转 Map 转 更新
  }

  //换一批
  Future<void> refushPeoplesLook({int sectionId}) async {
    course_index++;
    var r = await NetTools.dio.get<String>(
      "section/search/change?cursor=${course_index * 6}&sectionId=${sectionId}",
    );
    //缓存
    Global.netCache.cache.clear();
    homeMovieInfo.update((val) {
      if (convert.jsonDecode(r.data)['data'] != null) {
        //解析数据
        var sectionContents = new List<SectionContents>();
        convert.jsonDecode(r.data)['data'].forEach((v) {
          sectionContents.add(new SectionContents.fromJson(v));
        });

        //数据替换
        homeMovieInfo.update((val) {
          val.sections.forEach((element) {
            if (element.sectionType == "VIDEO" && element.display == "SCROLL") {
              element.sectionContents = sectionContents;
            }
          });
        });
      }
    });
  }
}