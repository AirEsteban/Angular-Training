import { Component, Injectable, OnInit } from '@angular/core';

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

  constructor() { }

  ngOnInit(): void {
  }

  CountOneTime() : void {
    this.times++;
  }

}
