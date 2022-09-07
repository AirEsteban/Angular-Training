import { Component, Injectable, OnInit, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-counter',
  templateUrl: './counter.component.html',
  styleUrls: ['./counter.component.css']
})
@Injectable({
 providedIn: 'root'
})

export class CounterComponent implements OnInit {

  times : number = 0;
  @Output() timesEmitter= new EventEmitter<any>();
  @Output() newItemEvent = new EventEmitter<string>();

  addNewItem(value: string) {
    this.newItemEvent.emit(value);
  }
  constructor() { }

  ngOnInit(): void {
  }

  CountOneTime() : void {
    this.times++;
    this.timesEmitter.emit(this.times);
  }

}
