import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:pokedex/team_up.dart';

class DetailScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String id;
  final String height;
  final String weight;
  final List<String> types;
  final Color color;

  DetailScreen({
    required this.name,
    required this.imageUrl,
    required this.id,
    required this.height,
    required this.weight,
    required this.types,
    this.color = const Color.fromARGB(255, 164, 164, 164),
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class Ability {
  final String name;
  final int value;

  Ability(this.name, this.value);
}

class Evolution {
  final String name;
  final String url;

  Evolution(this.name, this.url);
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  String description = '';
  late TabController _tabController;
  late List<Ability> abilities;
  late List<Evolution> evolutionChain = [];

  @override
  void initState() {
    super.initState();
    _fetchPokemonSpeciesData();
    _tabController = TabController(length: 3, vsync: this);
    abilities = [];
    _fetchAbilitiesData();
    _fetchEvolutionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchPokemonSpeciesData() async {
    var url =
        Uri.parse('https://pokeapi.co/api/v2/pokemon-species/${widget.id}');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        var flavorTextEntries = decodedData['flavor_text_entries'];
        var englishEntry = flavorTextEntries.firstWhere(
          (entry) => entry['language']['name'] == 'en',
          orElse: () => null,
        );

        setState(() {
          description = englishEntry != null
              ? englishEntry['flavor_text'].replaceAll('\n', ' ')
              : 'No description available.';
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _fetchAbilitiesData() async {
    var url = Uri.parse('https://pokeapi.co/api/v2/pokemon/${widget.id}');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        List<Ability> abilitiesData = [];
        decodedData['stats'].forEach((stat) {
          abilitiesData.add(Ability(stat['stat']['name'], stat['base_stat']));
        });

        setState(() {
          abilities = abilitiesData;
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _fetchEvolutionData() async {
    var url =
        Uri.parse('https://pokeapi.co/api/v2/pokemon-species/${widget.id}');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        var evolutionChainUrl = decodedData['evolution_chain']['url'];
        var evolutionDataResponse =
            await http.get(Uri.parse(evolutionChainUrl));
        if (evolutionDataResponse.statusCode == 200) {
          var evolutionData = jsonDecode(evolutionDataResponse.body);
          var chain = evolutionData['chain'];

          _extractEvolutions(chain);
        } else {
          print('Failed to fetch evolution data');
        }
      } else {
        print('Failed to fetch species data');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _extractEvolutions(Map<String, dynamic> chain) {
    if (chain.containsKey('species')) {
      String name = chain['species']['name'];
      String url = chain['species']['url'];
      setState(() {
        evolutionChain.add(Evolution(name, url));
      });
    }
    if (chain.containsKey('evolves_to')) {
      var evolvesTo = chain['evolves_to'] as List<dynamic>;
      if (evolvesTo.isNotEmpty) {
        _extractEvolutions(evolvesTo[0]);
      }
    }
  }

  Widget buildAbilitiesChart() {
    List<Color> barColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      const Color.fromARGB(255, 255, 230, 7),
      Colors.orange,
      const Color.fromARGB(255, 197, 94, 215),
    ];

    List<charts.Series<Ability, String>> series = [
      charts.Series(
        id: "Habilidades",
        data: abilities,
        domainFn: (Ability ability, _) => ability.name,
        measureFn: (Ability ability, _) => ability.value.toDouble(),
        colorFn: (_, index) => charts.ColorUtil.fromDartColor(
            barColors[index!.remainder(barColors.length)]),
        labelAccessorFn: (Ability ability, _) =>
            '${ability.name}: ${ability.value}', // Agregar nombre y valor
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Container(
        height: 300, // Altura de la gráfica
        child: charts.BarChart(
          series,
          animate: true,
          vertical: false, // Cambiado a horizontal

          domainAxis: charts.OrdinalAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(
              labelStyle: charts.TextStyleSpec(
                color: charts.MaterialPalette.black,
                fontSize: 12,
              ),
              lineStyle: charts.LineStyleSpec(
                color: charts.MaterialPalette.black,
              ),
            ),
          ),
          primaryMeasureAxis: charts.NumericAxisSpec(
            renderSpec: charts.GridlineRendererSpec(
              lineStyle: charts.LineStyleSpec(
                color: charts.MaterialPalette.gray
                    .shade400, // Color más claro para las líneas del eje
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAbilitiesList() {
    return Column(
      children: abilities.map((ability) {
        return ListTile(
          title: Text(
            ability.name,
            style: TextStyle(color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var heightScreen = MediaQuery.of(context).size.height;
    var widthScreen = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: widget.color,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            left: 5,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                Text(
                  "#${widget.id}",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          Positioned(
            top: 110,
            left: 22,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                widget.types.join(", "),
                style: TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Positioned(
            top: (heightScreen * 0.2),
            left: (widthScreen / 2) - 100,
            child: Hero(
              tag: widget.imageUrl,
              child: CachedNetworkImage(
                height: 200,
                width: 200,
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            child: Container(
              width: widthScreen,
              height: heightScreen * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: 'Description'),
                        Tab(text: 'Evolution'),
                        Tab(text: 'Abilities'),
                      ],
                      indicatorColor: widget.color,
                      labelColor: widget.color,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 30),
                                buildInfoRow(widthScreen, 'Name', widget.name),
                                buildInfoRow(
                                    widthScreen, 'Height', widget.height),
                                buildInfoRow(
                                    widthScreen, 'Weight', widget.weight),
                                SizedBox(height: 20),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                      color: Colors.blueGrey, fontSize: 17),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  description,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 17),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pestaña Evolution
                        // Pestaña Evolution
                        SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.builder(
                              shrinkWrap: true, // Agrega esta línea
                              physics:
                                  NeverScrollableScrollPhysics(), // Agrega esta línea
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    2, // Cambia el número de tarjetas por fila
                                crossAxisSpacing:
                                    20, // Aumenta el espacio entre las tarjetas
                                mainAxisSpacing:
                                    20, // Aumenta el espacio entre las filas de tarjetas
                                childAspectRatio:
                                    1.5, // Ajusta la relación de aspecto de las tarjetas
                              ),
                              itemCount: evolutionChain.length,
                              itemBuilder: (context, index) {
                                String imageUrl =
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${evolutionChain[index].url.split('/')[6]}.png';
                                return Card(
                                  elevation:
                                      5, // Agrega sombra a las tarjetas para resaltarlas
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height:
                                            120, // Ajusta la altura de la imagen
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit
                                              .contain, // Ajusta la forma en que se muestra la imagen
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              10), // Agrega espacio entre la imagen y el texto
                                      Text(
                                        evolutionChain[index].name,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Pestaña Abilities
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width:
                                      10), // Espacio entre la lista y el gráfico
                              Expanded(
                                flex: 2,
                                child: buildAbilitiesChart(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20, // Posición del botón
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamUp(
                      // Pasa los datos del Pokémon a TeamUpScreen
                      name: widget.name,
                      imageUrl: widget.imageUrl,
                      id: widget.id,
                      height: widget.height,
                      weight: widget.weight,
                      types: widget.types,
                    ),
                  ),
                );
              },
              child: Text('Team up!'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(double widthScreen, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: widthScreen * 0.3,
            child: Text(
              label,
              style: TextStyle(color: Colors.blueGrey, fontSize: 17),
            ),
          ),
          Container(
            child: Text(
              value,
              style: TextStyle(color: Colors.black, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}
