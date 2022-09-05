import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-products-list',
  templateUrl: './products-list.component.html',
  styleUrls: ['./products-list.component.css']
})

export class ProductsListComponent implements OnInit {
  ngOnInit(): void {
  }

  constructor(private counter : CounterComponent){

  }

  startCounter : Boolean = false;

  startToCount() : void{
    this.startCounter = true;
    this.counter.CountOneTime();
  }
}
