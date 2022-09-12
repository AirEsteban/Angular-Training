import { Component, OnInit } from '@angular/core';
import { PokeApiService } from '../poke-api.service';

@Component({
  selector: 'poke-card',
  templateUrl: './poke-card.component.html',
  styleUrls: ['./poke-card.component.css']
})
export class PokeCardComponent implements OnInit {

  name : String = '';
  imgSrc : String = '';
  shortDesc : String = '';
  moreInfo : String = 'See More...';

  constructor(private poke : PokeApiService) { }

  ngOnInit(): void {
    this.obtenerCharizard();
  }

  obtenerCharizard(){
    this.poke.getPokemonByName("charizard");
  }

}
