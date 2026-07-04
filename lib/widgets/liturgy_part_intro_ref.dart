import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartIntroRef extends StatelessWidget {
  final String? content;

  LiturgyPartIntroRef(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) {
          final zoomValue = currentZoom.value;
          return Padding(
              padding: EdgeInsets.only(top: 20, right: 15, bottom: 20),
              child: Align(
                  alignment: Alignment.topRight,
                  child: BiblicalReferenceButton(
                    reference: content != "" ? "- $content" : "",
                    zoom: zoomValue,
                  )));
        },
      );
    }
  }
}
