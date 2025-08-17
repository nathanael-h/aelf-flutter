import 'package:aelf_flutter/widgets/liturgy_part_content.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_intro.dart';
import 'package:aelf_flutter/widgets/liturgy_part_intro_ref.dart';
import 'package:aelf_flutter/widgets/liturgy_part_ref.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:flutter/material.dart';

/// A widget to display all liturgy widgets in a scrollable collumn
/// for one liturgy part. A part being a psalm or a reading, for examples.
/// This widget is made to be used in a tab view.
class LiturgyPartColumn extends StatelessWidget {
  final String? title, subtitle, intro, introRef, ref, content;
  final bool repeatSubtitle;

  const LiturgyPartColumn({
    this.title,
    this.subtitle,
    this.repeatSubtitle = false,
    this.intro,
    this.introRef,
    this.ref,
    this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            // title
            LiturgyPartTitle(title),
            // intro
            LiturgyPartIntro(intro),
            LiturgyPartIntroRef(introRef),
            // subtitle
            LiturgyPartSubtitle(subtitle),
            // reference
            LiturgyPartRef(ref),
            // content
            LiturgyPartContent(content),
            // subtitle again for psaumes antiennes
            (repeatSubtitle ? LiturgyPartSubtitle(subtitle) : Row()),
            // add bottom padding
            Padding(
              padding: EdgeInsets.only(bottom: 150),
            ),
          ]),
        ),
      ),
    );
  }
}
