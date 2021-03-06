import 'dart:async';
import 'dart:developer';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:pokedex/apimodels/Pokemon.dart';
import 'package:pokedex/apimodels/PokemonSpecies.dart';
import 'package:pokedex/configs/AppColors.dart';
import 'package:pokedex/consumers/ApiConsumer.dart';
import 'package:pokedex/consumers/PokemonLoader.dart';
import 'package:pokedex/models/pokeapi_model.dart';
import 'package:pokedex/models/session.model.dart';
import 'package:provider/provider.dart';

import '../../widgets/slide_up_panel.dart';
import 'widgets/info.dart';
import 'widgets/tab.dart';

import '../../helpers/HelperMethods.dart';

class FavouritesInfo extends StatefulWidget {
  const FavouritesInfo();

  @override
  _FavouritesInfoState createState() => _FavouritesInfoState();
}

class _FavouritesInfoState extends State<FavouritesInfo>
    with TickerProviderStateMixin {
  static const double _pokemonSlideOverflow = 20;

  AnimationController _cardController;
  AnimationController _cardHeightController;
  double _cardMaxHeight = 0.0;
  double _cardMinHeight = 0.0;
  GlobalKey _pokemonInfoKey = GlobalKey();

  @override
  void dispose() {
    _cardController.dispose();
    _cardHeightController.dispose();
    SessionModel.of(context).removeListener(changePokemon);

    super.dispose();
  }

  @override
  void initState() {
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _cardHeightController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 220));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      final appBarHeight = 60 + 22 + IconTheme.of(context).size;

      final RenderBox pokemonInfoBox =
          _pokemonInfoKey.currentContext.findRenderObject();

      _cardMinHeight =
          screenHeight - pokemonInfoBox.size.height + _pokemonSlideOverflow;
      _cardMaxHeight = screenHeight - appBarHeight;

      _cardHeightController.forward();
    });

    SessionModel.of(context).addListener(changePokemon);
    _loaded = false;
    super.initState();
  }

  bool _loaded;

  void concatToFuture(Future f, Function after) {
    log("concat " + after.toString());
    f.then(after);
  }

  Future<Pokemon> loadEverything(ApiConsumer<PokemonSpecies> species) {
    return species
        .getInfo()
        .then((x) =>
            Future.wait(x.eggGroups.map((egg) => egg.getInfo())).then((_) => x))
        .then((x) => x.evolutionChain
            .getInfo()
            .then((evo) => Future.wait(evo.chain.getAllInfo()))
            .then((_) => x))
        .then((x) => x.defaultVariety.pokemon.getInfo())
        .then((x) => Future.wait(x.stats.map((stat) => stat.stat.getInfo()))
            .then((_) => x))
        .then((x) => Future.wait(x.types.map((type) => type.type.getInfo()))
            .then((_) => x));
  }

  void changePokemon() {
    var entries = PokeapiModel.of(context).pokeIndex.entries;
    var selectedFav = SessionModel.of(context).selectedFavourite;
    var favourites = SessionModel.of(context).favouritesData.favourites;
    var species = entries
        .firstWhere((element) => element.id == selectedFav.pokemonId)
        .species;
    loadEverything(species).then((x) {
      log("loaded " + x.id.toString());
      this.setState(() => _loaded = true);
    });
    var list = favourites
        .map((x) =>
            entries.firstWhere((element) => element.id == x.pokemonId).species)
        .toList();
    var actual = SessionModel.of(context).favouritesIndex;
    var next = list.getRange(actual, Math.min(actual + 5, list.length));
    var prev = list.getRange(Math.max(0, actual - 5), actual);

    next.followedBy(prev).forEach((x) => loadEverything(x)
        .then((res) => log("loaded next " + res.id.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableProvider(
      create: (context) => _cardController,
      child: MultiProvider(
        providers: [ListenableProvider.value(value: _cardController)],
        child: Scaffold(
          body: Consumer2<PokeapiModel, SessionModel>(
            builder: (_, model, session, child) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                color: model.pokeIndex.entries
                            .firstWhere((e) =>
                                e.id == session.selectedFavourite.pokemonId)
                            .species
                            .info
                            ?.defaultVariety
                            ?.pokemon
                            ?.info
                            ?.types
                            ?.tryGet(0)
                            ?.type
                            ?.info !=
                        null
                    ? AppColors.types[model.pokeIndex.entries
                            .firstWhere((e) =>
                                e.id == session.selectedFavourite.pokemonId)
                            .species
                            .info
                            .defaultVariety
                            .pokemon
                            .info
                            .types[0]
                            .type
                            .info
                            .id -
                        1]
                    : AppColors.grey,
                child: Stack(
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _cardHeightController,
                      child: PokemonTabInfo(),
                      builder: (context, child) {
                        return SlidingUpPanel(
                          controller: _cardController,
                          minHeight:
                              _cardMinHeight * _cardHeightController.value,
                          maxHeight: _cardMaxHeight,
                          child: child,
                        );
                      },
                    ),
                    IntrinsicHeight(
                      child: Container(
                        key: _pokemonInfoKey,
                        child: PokemonOverallInfo(),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
