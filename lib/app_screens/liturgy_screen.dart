import 'dart:convert';
import 'package:aelf_flutter/settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:connectivity/connectivity.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen(this.liturgyType, this.liturgyDate, this.refresh) : super();

  static const routeName = '/liturgyScreen';

  final String liturgyDate;
  final String liturgyType;
  final int refresh;

  @override
  _LiturgyScreenState createState() => _LiturgyScreenState();
}


enum LiturgyLoadingState {
  Loading,
  Loaded,
  NoCacheNointernet
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {

  // LoadingState
  LiturgyLoadingState loadingState = LiturgyLoadingState.Loading;
  
  // aelf settings
  static const String apiUrl = 'https://api.aelf.org/v1/';

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
    _getAELFLiturgy().then((obj){
      setState(() {
      // format liturgy
      liturgyFormatter.parseLiturgy(this, context, widget.liturgyType, obj);
      loadingState = LiturgyLoadingState.Loaded;
    });
    }).catchError((Exception exception){
    setState(() {
      liturgyFormatter.displayMessage(this, context, widget.liturgyType, exception.toString());
      loadingState = LiturgyLoadingState.NoCacheNointernet;
    });
    });
  }

  Future _getAELFLiturgy() async {
    print(widget.liturgyDate + ' ' + widget.liturgyType);
    // rep - server or db response
    Liturgy rep =
        await liturgyDbHelper.getRow(widget.liturgyDate, widget.liturgyType);

    if (rep != null) {
      var obj = json.decode(rep.content);
      //_displayAelfLiturgy(obj);
      print("db yes");
      return obj;
    } else {
      print("db no");
      //check internet connection
      ConnectivityResult connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        return _getAELFLiturgyOnWeb(widget.liturgyDate, widget.liturgyType);
      } else {
        throw Exception("Connectez-vous pour voir cette lecture.");
        // clear actualy date to refresh page when connect to internet
      }
    }
    
  }

  Future<dynamic> _getAELFLiturgyOnWeb(String type, String date) async {
    String liturgyZone = await getPrefRegion();


      _displayProgressIndicator();
      // get aelf content in their web api
      final response = await http.get(
          '$apiUrl${widget.liturgyType}/${widget.liturgyDate}/$liturgyZone');
      if (response.statusCode == 200) {
        var obj = json.decode(response.body);
        return obj[widget.liturgyType];
      } else if (response.statusCode == 404) {
        // this liturgy not exist -> display message
        throw Exception ("Nous n'avons pas trouvé cette lecture.");
      } else {
        // If the server did not return a 200 OK response,
        //log('get aelf from api ${response.statusCode} error'); // todo add message not found 404
        //throw Exception('Failed to load aelf');
        throw Exception("La connexion au serveur à échoué.");
      }

  }

// display this message when aelf return not found status

  void _displayProgressIndicator() {
    setState(() {
      // format liturgy
      liturgyFormatter.displayProgressIndicator(this, context, widget.liturgyType);
    });
  }


  detectRefreshRequest() {
    if (_liturgyRefresh != widget.refresh) {
      //load function to get current liturgy
      _liturgyRefresh = widget.refresh;
      this._getAELFLiturgy();
    }
  }

  @override
  Widget build(BuildContext context) {
    // detect if main ask to refresh that vue
    // detectRefreshRequest();
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
                        indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                        labelColor: Theme.of(context).scaffoldBackgroundColor,
                        unselectedLabelColor:
                            Theme.of(context).scaffoldBackgroundColor,
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
