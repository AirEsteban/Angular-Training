import { Component, Injectable ,OnInit } from '@angular/core';
import { CounterComponent } from '../counter/counter.component'

@Component({
  selector: 'app-products-list',
  templateUrl: './products-list.component.html',
  styleUrls: ['./products-list.component.css']
})

export class ProductsListComponent implements OnInit {
  ngOnInit(): void {
  }

  constructor( private counter : CounterComponent){

  }
  btnMsg : String = "Click to start counting";
  startCounter : Boolean = false;

  startToCount() : void{
    if(!this.startCounter){
      this.startCounter = true;
      this.btnMsg = "Count another";
    }
    this.counter.CountOneTime();
  }
}
