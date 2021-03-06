import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/apimodels/PokemonBaseStat.dart';
import 'package:pokedex/models/pokeapi_model.dart';
import 'package:pokedex/models/session.model.dart';
import 'package:provider/provider.dart';

import '../../../configs/AppColors.dart';
import '../../../apimodels/Pokemon.dart';
import '../../../widgets/progress.dart';

class TabStats extends StatelessWidget {
  const TabStats({
    Key key,
    @required this.animation,
    @required this.label,
    @required this.value,
    this.progress,
  }) : super(key: key);

  final Animation animation;
  final String label;
  final num value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress == null ? this.value / 100 : this.progress;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: AppColors.black.withOpacity(0.6)),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text("$value"),
        ),
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, widget) => ProgressBar(
              progress: animation.value * progress,
              color: progress < 0.5 ? AppColors.red : AppColors.teal,
            ),
          ),
        ),
      ],
    );
  }
}

class PokemonBaseStats extends StatefulWidget {
  const PokemonBaseStats({Key key}) : super(key: key);

  @override
  _PokemonBaseStatsState createState() => _PokemonBaseStatsState();
}

class _PokemonBaseStatsState extends State<PokemonBaseStats>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    CurvedAnimation curvedAnimation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _controller,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

    _controller.forward();
  }

  List<Widget> generateStatWidget(Pokemon pokemon) {
    Map<String, int> stats = new Map();

    for (var stat in pokemon.stats) {
      PokemonBaseStat baseStat = stat.stat.info;
      stats[baseStat.names["es"]] = stat.value;
    }

    var widgets = stats.keys
        .map((x) => TabStats(animation: _animation, label: x, value: stats[x]))
        .expand((x) => [
              x,
              SizedBox(
                height: 14,
              )
            ]);

    return widgets.take(widgets.length - 1).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Consumer2<PokeapiModel, SessionModel>(
        builder: (_, model, session, child) => !(model.pokeIndex.entries
                    .firstWhere(
                        (e) => e.id == session.selectedFavourite.pokemonId)
                    .species
                    .info
                    ?.defaultVariety
                    ?.pokemon
                    ?.info
                    ?.stats
                    ?.every((x) => x.stat.hasInfo) ??
                false)
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  ...generateStatWidget(model.pokeIndex.entries
                      .firstWhere(
                          (e) => e.id == session.selectedFavourite.pokemonId)
                      .species
                      .info
                      .defaultVariety
                      .pokemon
                      .info),
                  SizedBox(height: 27),
                  Text(
                    "Type defenses",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 0.8,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "The effectiveness of each type on ${model.pokeIndex.entries.firstWhere((e) => e.id == session.selectedFavourite.pokemonId).species.info.names["es"]}.",
                    style: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  ),
                ],
              ),
      ),
    );
  }
}
