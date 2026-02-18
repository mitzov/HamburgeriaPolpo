import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { interval, Subscription } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './app.html',
  styleUrls: ['./app.css']
})
export class AppComponent implements OnInit, OnDestroy {
  ordini: any[] = [];
  prodotti: any[] = [];
  nuovoProdotto = { name: '', category: 'panini', price: 0 };
  ordineRapido: any = {};
  carrelloRapido: any[] = [];
  apiUrl = '/api';
  private refreshSubscription: Subscription | null = null;

  constructor(private http: HttpClient) {
    this.initOrdineRapido();
  }

  ngOnInit() {
    this.caricaTutto();
    this.avviaAutoRefresh();
  }

  ngOnDestroy() {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
    }
  }

  avviaAutoRefresh() {
    this.refreshSubscription = interval(2000).subscribe(() => {
      this.caricaTutto();
    });
  }

  initOrdineRapido() {
    this.ordineRapido = {};
  }

  caricaTutto() {
    this.http.get<any[]>(`${this.apiUrl}/orders`).subscribe(
      res => this.ordini = res,
      err => console.error('Errore caricamento ordini:', err)
    );
    this.http.get<any[]>(`${this.apiUrl}/menu`).subscribe(
      res => this.prodotti = res,
      err => console.error('Errore caricamento menu:', err)
    );
  }

  cambiaStato(id: number, stato: string) {
    this.http.patch(`${this.apiUrl}/orders/${id}`, { status: stato }).subscribe(
      () => this.caricaTutto(),
      err => console.error('Errore cambio stato:', err)
    );
  }

  aggiungi() {
    if (!this.nuovoProdotto.name) {
      alert('Inserisci nome prodotto!');
      return;
    }
    this.http.post(`${this.apiUrl}/menu`, this.nuovoProdotto).subscribe(
      () => {
        this.caricaTutto();
        this.nuovoProdotto = { name: '', category: 'panini', price: 0 };
      },
      err => console.error('Errore aggiunta prodotto:', err)
    );
  }

  addAlCarrello(prodotto: any) {
    if (!this.ordineRapido[prodotto.id]) {
      this.ordineRapido[prodotto.id] = { ...prodotto, qty: 1 };
    } else {
      this.ordineRapido[prodotto.id].qty++;
    }
  }

  removeCarrello(id: number) {
    delete this.ordineRapido[id];
    this.ordineRapido = { ...this.ordineRapido };
  }

  creatOrdineRapido() {
    const items = Object.values(this.ordineRapido).map((p: any) => ({
      id: p.id,
      name: p.name,
      quantity: p.qty,
      price: p.price
    }));

    if (items.length === 0) {
      alert('Aggiungi prodotti al carrello!');
      return;
    }

    const totalPrice = items.reduce((sum: number, item: any) => sum + (item.price * item.quantity), 0);
    
    const ordine = {
      items: items,
      total_price: totalPrice
    };

    this.http.post(`${this.apiUrl}/orders`, ordine).subscribe(
      () => {
        alert('Ordine creato!');
        this.ordineRapido = {};
        this.caricaTutto();
      },
      err => {
        console.error('Errore creazione ordine:', err);
        alert('Errore: ' + (err.error?.detail || 'Errore sconosciuto'));
      }
    );
  }

  getTotaleCarrello(): number {
    return Object.values(this.ordineRapido).reduce((sum: number, item: any) => 
      sum + (item.price * item.qty), 0);
  }

  hasItemsInCarrello(): boolean {
    return Object.keys(this.ordineRapido).length > 0;
  }
}