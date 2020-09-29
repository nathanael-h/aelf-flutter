import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:connectivity/connectivity.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen(this.liturgyType, this.liturgyDate, this.liturgyRegion, this.refresh) : super();

  static const routeName = '/liturgyScreen';

  final String liturgyDate;
  final String liturgyType;
  final String liturgyRegion;
  final int refresh;

  @override
  _LiturgyScreenState createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  // aelf settings
  String apiUrl = 'https://api.aelf.org/v1/';

  // refresh value to save previous refresh and not refresh limitless
  int _liturgyRefresh = -1;

  // add liturgy db helper
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  final LiturgyFormatter liturgyFormatter = new LiturgyFormatter();

  @override
  void initState() {
    super.initState();
    // init tab controller
    liturgyFormatter.initTabController(this);
  }

  void _getAELFLiturgy() async {
    print(widget.liturgyDate + ' ' + widget.liturgyType + ' ' + widget.liturgyRegion);
    // rep - server or db response
    Liturgy rep =
        await liturgyDbHelper.getRow(widget.liturgyDate, widget.liturgyType, widget.liturgyRegion);

    if (rep != null) {
      var obj = json.decode(rep.content);
      _displayAelfLiturgy(obj);
      print("db yes");
    } else {
      print("db no");
      //check internet connection
      ConnectivityResult connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        _getAELFLiturgyOnWeb(widget.liturgyDate, widget.liturgyType);
      } else {
        _displayMessage("Connectez-vous pour voir cette lecture.");
        // clear actualy date to refresh page when connect to internet
      }
    }
  }

  void _getAELFLiturgyOnWeb(String type, String date) async {
    //String liturgyRegion = await getPrefRegion() ?? "romain";

    try {
      _displayProgressIndicator();
      // get aelf content in their web api
      final response = await http.get(
          '$apiUrl${widget.liturgyType}/${widget.liturgyDate}/${widget.liturgyRegion}');
      print('liturgy_screen = $apiUrl${widget.liturgyType}/${widget.liturgyDate}/${widget.liturgyRegion}');
      if (response.statusCode == 200) {
        var obj = json.decode(response.body);
        _displayAelfLiturgy(obj[widget.liturgyType]);
      } else if (response.statusCode == 404) {
        // this liturgy not exist -> display message
        _displayMessage("Nous n'avons pas trouvé cette lecture.");
      } else {
        // If the server did not return a 200 OK response,
        //log('get aelf from api ${response.statusCode} error'); // todo add message not found 404
        //throw Exception('Failed to load aelf');
        _displayMessage("La connexion au serveur à échoué.");
      }
    } catch (error) {
      print("getAELFLiturgyOnWeb in liturgy screen error: " + error.toString());
    }
  }

// display this message when aelf return not found status
  void _displayMessage(String content) {
    setState(() {
      liturgyFormatter.displayMessage(this, context, widget.liturgyType, content);
    });
  }

  void _displayProgressIndicator() {
    setState(() {
      // format liturgy
      liturgyFormatter.displayProgressIndicator(this, context, widget.liturgyType);
    });
  }

  void _displayAelfLiturgy(var obj) {
    setState(() {
      // format liturgy
      liturgyFormatter.parseLiturgy(this, context, widget.liturgyType, obj);
    });
  }

  detectRefreshRequest() {
    if (_liturgyRefresh != widget.refresh) {
      //load function to get current liturgy
      _liturgyRefresh = widget.refresh;
      this._getAELFLiturgy();
      print("Refresh liturgy");
    }
  }

  @override
  Widget build(BuildContext context) {
    // detect if main ask to refresh that vue
    detectRefreshRequest();
    // return widget
    return DefaultTabController(
      length: liturgyFormatter.tabMenu.length,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Theme.of(context).primaryColor,
                    child: Center(
                      child: TabBar(
                        indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                        labelColor: Theme.of(context).tabBarTheme.labelColor,
                        unselectedLabelColor:
                            Theme.of(context).tabBarTheme.unselectedLabelColor,
                        labelPadding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.1),
                        isScrollable: true,
                        controller: liturgyFormatter.tabController,
                        tabs: liturgyFormatter.tabMenu,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: liturgyFormatter.tabController,
                children: liturgyFormatter.tabChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
