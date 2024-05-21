import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_screen.dart';
import 'team.dart'; // Importa la página del equipo

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  List<dynamic> pokedex = [];
  List<dynamic> filteredPokedex = [];
  String searchQuery = '';
  int offset = 0;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPokemonData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoading) {
        _fetchMorePokemonData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchPokemonData() async {
    setState(() {
      isLoading = true;
    });
    var url = Uri.parse('$baseUrl?offset=$offset&limit=20');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        var pokemonList = decodedData['results'];

        for (var pokemon in pokemonList) {
          var pokemonDetails = await http.get(Uri.parse(pokemon['url']));
          if (pokemonDetails.statusCode == 200) {
            var pokemonData = jsonDecode(pokemonDetails.body);
            var id = pokemonData['id'];
            var imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
            pokedex.add({
              'name': _capitalize(pokemonData['name']),
              'imageUrl': imageUrl,
              'id': id.toString(),
              'height': pokemonData['height'].toString(),
              'weight': pokemonData['weight'].toString(),
              'types': (pokemonData['types'] as List)
                  .map((typeInfo) => _capitalize(typeInfo['type']['name']))
                  .toList(),
            });
          }
        }

        setState(() {
          offset += 20;
          isLoading = false;
          _filterPokemon();
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _fetchMorePokemonData() async {
    if (!isLoading) {
      _fetchPokemonData();
    }
  }

  void _filterPokemon() {
    setState(() {
      filteredPokedex = pokedex.where((pokemon) {
        final nameMatch =
            pokemon['name'].toLowerCase().contains(searchQuery.toLowerCase());
        return nameMatch;
      }).toList();
    });
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/International_Pok%C3%A9mon_logo.svg/1024px-International_Pok%C3%A9mon_logo.svg.png',
              height: 40,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Image.asset('images/pokeball.png'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TeamPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Find your Pokemon',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterPokemon();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: (filteredPokedex.length / 2).ceil() + 1,
              itemBuilder: (context, index) {
                if (index == (filteredPokedex.length / 2).ceil()) {
                  return Center(
                    child: isLoading
                        ? CircularProgressIndicator()
                        : SizedBox.shrink(),
                  );
                }
                var startIndex = index * 2;
                var endIndex = startIndex + 2;
                if (endIndex > filteredPokedex.length) {
                  endIndex = filteredPokedex.length;
                }
                var pokemonList = filteredPokedex.sublist(startIndex, endIndex);
                return Row(
                  children: pokemonList.map((pokemon) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                name: pokemon['name'],
                                imageUrl: pokemon['imageUrl'],
                                id: pokemon['id'],
                                height: pokemon['height'],
                                weight: pokemon['weight'],
                                types: pokemon['types'],
                              ),
                            ),
                          ).then((_) {
                            // Actualiza el estado cuando regresas desde la pantalla de detalles
                            setState(() {
                              searchQuery = '';
                              _filterPokemon();
                            });
                          });
                        },
                        child: Card(
                          margin: EdgeInsets.all(10),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      pokemon['imageUrl'],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        _capitalize(pokemon['name']),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
