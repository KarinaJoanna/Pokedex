import 'package:flutter/material.dart';
import 'home_screen.dart';

class TeamPage extends StatefulWidget {
  static List<Map<String, dynamic>> _team = [];

  static List<Map<String, dynamic>> get team => _team;

  @override
  _TeamPageState createState() => _TeamPageState();

  static void addPokemonToTeam(Map<String, dynamic> pokemonData) {
    if (_team.length < 3) {
      _team.add(pokemonData); // Agrega el pokémon a la lista del equipo
    }
  }

  static void removePokemonFromTeam(int index) {
    _team.removeAt(index); // Elimina el pokémon del equipo en el índice dado
  }
}

class _TeamPageState extends State<TeamPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        ),
      ),
      body: ListView.builder(
        itemCount: TeamPage._team.length,
        itemBuilder: (context, index) {
          var pokemon = TeamPage._team[index];
          return Dismissible(
            key: UniqueKey(),
            onDismissed: (direction) {
              setState(() {
                TeamPage.removePokemonFromTeam(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${pokemon['name']} removed from team!')),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
            direction: DismissDirection.startToEnd,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Container(
                    width: MediaQuery.of(context).size.width *
                        0.8, // Ajusta el ancho de la tarjeta
                    child: Column(
                      children: [
                        Image.network(
                          pokemon['imageUrl'],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 8),
                        Text(
                          pokemon['name'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ID: ${pokemon['id']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
