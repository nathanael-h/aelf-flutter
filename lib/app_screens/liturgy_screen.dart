import 'dart:developer';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

class LiturgyScreen extends StatefulWidget {
  static const routeName = '/liturgyScreen';

  final String liturgyType;
  final String liturgyDate;

  //LiturgyScreen(this.liturgyType, this.liturgyDate);
  

  LiturgyScreen(this.liturgyType, this.liturgyDate) : super();
  @override
  _LiturgyScreenState createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  
  String liturgyZone = 'france';
  String apiUrl = 'https://api.aelf.org/v1/';

  TabController _tabController;
  var _tabMenu = [
    Tab(text: ""),
  ];
  var _tabChild = <Widget>[Center()];
  var _massPos = [];

  @override
  void initState() {
    super.initState();
    _tabController =
        new TabController(vsync: this, length: this._tabMenu.length);
    getAELFLiturgy();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void setTabController(int index) {
    this._tabController.animateTo(
        this._tabMenu.length >= index && index > 0 ? this._massPos[index] : 0);
  }

  void getAELFLiturgy() async {
    //String date = "${selectedDate.toLocal()}".split(' ')[0];
    final response = await http.get(
        '$apiUrl${widget.liturgyType}/${widget.liturgyDate}/${this.liturgyZone}');
    if (response.statusCode == 200) {
      var obj = json.decode(response.body);
      displayAelfLiturgy(obj[widget.liturgyType]);
    } else {
      // If the server did not return a 200 OK response,
      log('get aelf from api ${response.statusCode} error'); // todo add message not found 404
      throw Exception('Failed to load aelf');
    }
  }

  void displayAelfLiturgy(var obj) {
    String title, subtitle, ref, nb;
    // reset tab controller
    setTabController(0);

    setState(() {
      // reset tabs
      this._tabMenu = [];
      this._tabChild = <Widget>[];

      if (widget.liturgyType == "messes") {
        this._massPos = [];
        for (var e = 0; e < obj.length; e++) {
          if (obj.length > 1) {
            // display the different mass if there are several
            List<Widget> list = new List<Widget>();
            for (var i = 0; i < obj.length; i++) {
              list.add(new GestureDetector(
                  onTap: () {
                    // move to tab when select mass
                    setTabController(i);
                  },
                  child: Container(
                    margin: EdgeInsets.all(30.0),
                    padding: EdgeInsets.all(10.0),
                    alignment: Alignment.topCenter,
                    width: MediaQuery.of(context).size.width - 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromRGBO(191, 35, 41, 1.0)),
                      color: (i == e ? Color.fromRGBO(191, 35, 41, 1.0) : null),
                    ),
                    child: Text(obj[i]["nom"],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30)),
                  )));
            }
            // add mass menu
            this._massPos.add(this._tabMenu.length);
            this._tabMenu.add(Tab(text: "Messes"));
            this._tabChild.add(Container(
                  padding: EdgeInsets.only(top: 100),
                  alignment: Alignment.center,
                  child: Column(children: list),
                ));
          }

          // display each mass elements
          for (int i = 0; i < obj[e]["lectures"].length; i++) {
            List index = [
              "Première",
              "Deuxième",
              "Troisième",
              "Quatrième",
              "Cinqième",
              "Sixième",
              "Septième",
              "Huitième",
              "Neuvième",
              "Dixième"
            ];
            Map el = obj[e]["lectures"][i];
            ref = el.containsKey("ref") ? el["ref"] : "";
            switch (el["type"]) {
              case 'sequence':
                {
                  this._tabMenu.add(Tab(text: "Séquence"));
                  this._tabChild.add(displayContainer(
                      "Séquence", "", false, "", el["contenu"]));
                }
                break;
              case 'entree_messianique':
                {
                  this._tabMenu.add(Tab(text: "Entrée messianique"));
                  this._tabChild.add(displayContainer("Entrée messianique",
                      el["intro_lue"], false, ref, el["contenu"]));
                }
                break;
              case 'psaume':
                {
                  this._tabMenu.add(Tab(text: "Psaume"));
                  this._tabChild.add(displayContainer(
                      "Psaume",
                      el["refrain_psalmique"],
                      false,
                      (ref != "" ? "Ps $ref" : ""),
                      el["contenu"]));
                }
                break;
              case 'evangile':
                {
                  this._tabMenu.add(Tab(text: "Évangile"));
                  this._tabChild.add(displayContainer(
                      el["titre"], el["intro_lue"], false, ref, el["contenu"]));
                }
                break;
              default:
                {
                  if (el["type"].contains("lecture_")) {
                    nb = el["type"].split('_')[1];
                    title = index.length >= int.parse(nb)
                        ? "${index[int.parse(nb) - 1]} Lecture"
                        : "Lecture $nb";
                    this._tabMenu.add(Tab(text: title));
                    this._tabChild.add(displayContainer(el["titre"],
                        el["intro_lue"], false, ref, el["contenu"]));
                  }
                }
                break;
            }
          }
        }
      } else if (widget.liturgyType == "informations") {
        // display informations
        List info = [
          "zone",
          "couleur",
          "annee",
          "temps_liturgique",
          "semaine",
          "jour_liturgique_nom",
          "fete",
          "degre"
        ];
        List infoName = [
          "Zone",
          "Couleur",
          "Année",
          "Temps liturgique",
          "Semaine",
          "Jour liturgique",
          "Fête",
          "Degré"
        ];

        List<Widget> list = new List<Widget>();
        for (var i = 0; i < info.length; i++) {
          if (obj.containsKey(info[i]) && obj[info[i]] != "") {
            list.add(
              new ListTile(
                leading: Icon(Icons.arrow_right),
                title: Text(infoName[i]),
                subtitle: Text(obj[info[i]]),
              ),
            );
          }
        }
        this._tabMenu.add(Tab(text: "Informations"));
        this._tabChild.add(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: list,
              ),
            );
      } else {
        // for each element in others types -> add to new tabs
        obj.forEach((k, v) {
          if (v.length != 0) {
            // get text reference
            ref = "";
            if (v.runtimeType != String && v.runtimeType != int) {
              ref = v.containsKey("reference") ? v["reference"] : "";
            }

            switch (k) {
              case 'introduction':
                {
                  this._tabMenu.add(Tab(text: "Introduction"));
                  this
                      ._tabChild
                      .add(displayContainer("Introduction", "", true, "", v));
                }
                break;
              case 'psaume_invitatoire':
                {
                  this._tabMenu.add(Tab(text: "Antienne invitatoire"));
                  this._tabChild.add(displayContainer(
                      "Antienne invitatoire",
                      obj["antienne_invitatoire"],
                      true,
                      (ref != "" ? "Ps $ref" : ""),
                      v["texte"]));
                }
                break;
              case 'hymne':
                {
                  this._tabMenu.add(Tab(text: "Hymne"));
                  this._tabChild.add(displayContainer(
                      "Hymne", v["titre"], false, "", v["texte"]));
                }
                break;
              case 'pericope':
                {
                  this._tabMenu.add(Tab(text: "Parole de Dieu"));
                  this._tabChild.add(displayContainer(
                      "Parole de Dieu",
                      "",
                      false,
                      ref,
                      v["texte"] + "<br><br><br><br>" + obj["repons"]));
                }
                break;
              case 'lecture':
                {
                  this._tabMenu.add(Tab(text: "Lecture"));
                  this._tabChild.add(displayContainer(
                      "« " + capitalize(v["titre"]) + " »",
                      "",
                      false,
                      ref,
                      v["texte"] + "<br><br><br><br>" + obj["repons_lecture"]));
                }
                break;
              case 'texte_patristique':
                {
                  this._tabMenu.add(Tab(text: "Lecture patristique"));
                  this._tabChild.add(displayContainer(
                      "« " + capitalize(obj["titre_patristique"]) + " »",
                      ref,
                      false,
                      ref,
                      v + "<br><br><br><br>" + obj["repons_patristique"]));
                }
                break;
              case 'intercession':
                {
                  this._tabMenu.add(Tab(text: "Intercession"));
                  this
                      ._tabChild
                      .add(displayContainer("Intercession", "", false, ref, v));
                }
                break;
              case 'notre_pere':
                {
                  this._tabMenu.add(Tab(text: "Notre Père"));
                  this._tabChild.add(displayContainer(
                      "Notre Père",
                      "",
                      false,
                      "",
                      "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>Donne-nous aujourd’hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>comme nous pardonnons aussi à ceux qui nous ont offensés.<br>Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen"));
                }
                break;
              case 'oraison':
                {
                  this._tabMenu.add(Tab(text: "Oraison"));
                  this
                      ._tabChild
                      .add(displayContainer("Oraison", "", false, ref, v));
                }
                break;
              default:
                {
                  if (k.contains("psaume_") || k.contains("cantique_")) {
                    nb = k.split('_')[1];
                    title = k.contains("psaume_")
                        ? "Psaume " + v["reference"]
                        : v["titre"];
                    subtitle = obj.containsKey("antienne_" + nb)
                        ? obj["antienne_" + nb]
                        : "";

                    if (k.contains("psaume_") &&
                        v["reference"].toLowerCase().contains("cantique")) {
                      var t = ref.split("(");
                      if (t.length > 0) {
                        title = capitalize(t[0]);
                      }
                      if (t.length > 1) {
                        RegExp exp =
                            new RegExp(r"(\(|\).|\))", caseSensitive: false);
                        ref = t[1].replaceAll(exp, "");
                      }
                    } else if (k.contains("psaume_")) {
                      ref = "";
                    }
                    this._tabMenu.add(Tab(text: title));
                    this._tabChild.add(displayContainer(
                        title, subtitle, true, ref, v["texte"]));
                  }
                }
                break;
            }
          }
        });
      }
      // reset tab controller and his index
      _tabController =
          new TabController(vsync: this, length: this._tabMenu.length);
      setTabController(0);
    });
  }

  String capitalize(String s) {
    if (s.length <= 1) {
      return "";
    }
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  dynamic displayContainer(String title, String subtitle, bool repeatSubtitle,
      String ref, String content) {
    String bis = "";
    if (repeatSubtitle) {
      bis = subtitle;
    }
    return Container(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(children: <Widget>[
          Row(children: [
            Html(
              data: title,
              padding: EdgeInsets.only(top: 25, bottom: 5, left: 15, right: 15),
              defaultTextStyle: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w900,
                  fontSize: 20),
            ),
          ]),
          Padding(
              padding: EdgeInsets.only(right: 15),
              child: Align(
                alignment: Alignment.topRight,
                child: Text((ref != "" ? "- $ref" : ""),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              )),
          Row(children: [
            Html(
              data: subtitle,
              padding: EdgeInsets.only(top: 20, bottom: 0, left: 15, right: 15),
              defaultTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
          ]),
          Row(children: [
            Html(
              data: content,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              defaultTextStyle: TextStyle(fontSize: 16),
              customRender: (node, children) {
                if (node is dom.Element) {
                  switch (node.localName) {
                    case "span": // using this, you can handle custom tags in your HTML
                      String txt = children[0]
                          .toString()
                          .replaceAll('Text\(\"', '')
                          .replaceAll('"\)', '');
                      return Text(txt,
                          style: TextStyle(
                              fontSize: 10, height: 1.8, color: Colors.red));
                      break;
                  }
                }
              },
            ),
          ]),
          Row(children: [
            Html(
              data: bis,
              padding: EdgeInsets.only(left: 15, right: 15, bottom: 100),
              defaultTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabMenu.length,
      child: Scaffold(
        appBar: TabBar(
          labelColor: Color.fromRGBO(191, 35, 41, 1.0),
          unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4),
          labelPadding: EdgeInsets.symmetric(horizontal:MediaQuery.of(context).size.width*0.1),         
          isScrollable: true,
          controller: _tabController,
          tabs: _tabMenu,
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabChild,
        ),
      ),
    );
  }
}
