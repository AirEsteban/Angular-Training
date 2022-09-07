import { Component ,OnInit } from '@angular/core';
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
  btnMsg : String = "Click to start adding buttons";
  startCounter : Boolean = false;
  items = ['item1', 'item2', 'item3', 'item4'];

  addItem(newItem: string) {
    this.items.push(newItem);
  }
  
  startToCount() : void{
    if(!this.startCounter){
      this.startCounter = true;
      this.btnMsg = "Count another";
    }
  }
}
