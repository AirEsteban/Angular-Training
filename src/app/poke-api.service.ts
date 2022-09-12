import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http'

@Injectable({
  providedIn: 'root'
})
export class PokeApiService {

  baseUrl : String = 'https://pokeapi.co/api/v2/';

  constructor(private http : HttpClient) { }

  getPokemonByName(pokemonName : String){
      let pokeJSON = this.http.get(this.baseUrl + "/pokemon/" + pokemonName);
      console.log(pokeJSON);
  }
}
