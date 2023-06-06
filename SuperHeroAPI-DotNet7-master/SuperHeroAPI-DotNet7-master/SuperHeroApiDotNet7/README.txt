// Intro: watch https://www.youtube.com/watch?v=8pH5Lv4d5-g

// Download and install Visual Studio 2022
// Download and install VS Code


Open Visual Studio 2022
Create new project . ASP.NT Core Web API (not minimal, use controllers, enable OpenAPI support to get Swagger)
Add New API controller
(optionally use API with read/write endpoints using Entity Framework)

// Install dependencies

// Entity Framework
// In terminal
// Check if you have ef
dotnet ef
 // Install if you do not, or update, or uninstall and install, is up to you
dotnet tool install --global dotnet-ef
dotnet tool update --global dotnet-ef
dotnet tool uninstall --global dotnet-ef

Go to Tools > Package NuGet Manager > Browse tab, add 
Microsoft.EntitityFrameworkCore
Microsoft.EntitityFrameworkCore.Design
Microsoft.EntitityFrameworkCore.SqlServer
AutoMapper.Extensions.Microsoft.DependencyInjection

// Download and install SQL Server Express or Community Edition
// Download and install SQL Server Management Studio

Add a Models folder
Add a new class, make a model for the new table
Add additional classes for other tables


// Create the dabatase
dotnet ef migrations add InitialCreate
dotnet ef database update

/// Enhance by adding an Angular front end

To create an Angular app that performs CRUD operations on the SuperHero model, 

namespace SuperHeroApiDotNet7.Models
{
    public class SuperHero
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Place { get; set; } = string.Empty;

    }
}

 you'll need to follow these steps:

Step 1: Set up your Angular development environment

Install Node.js and npm (Node Package Manager) if not already installed.
Install the Angular CLI (Command Line Interface) by running the following command in your terminal:
bash

npm install -g @angular/cli
Step 2: Generate a new Angular app

Open a terminal and navigate to the desired directory where you want to create your app.
Run the following command to generate a new Angular app:
arduino

ng new superhero-app
Change into the app directory:
bash

cd superhero-app
Step 3: Create the SuperHero service

Generate a new service to handle HTTP requests for the SuperHero model:
java

ng generate service super-hero
Replace the contents of the generated super-hero.service.ts file with the following code:
typescript

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { SuperHero } from './super-hero.model';

@Injectable({
  providedIn: 'root'
})
export class SuperHeroService {
  private apiUrl = 'http://localhost:3000/superheroes'; // Replace with your API endpoint

  constructor(private http: HttpClient) { }

  getSuperHeroes(): Observable<SuperHero[]> {
    return this.http.get<SuperHero[]>(this.apiUrl);
  }

  getSuperHero(id: number): Observable<SuperHero> {
    const url = `${this.apiUrl}/${id}`;
    return this.http.get<SuperHero>(url);
  }

  addSuperHero(superHero: SuperHero): Observable<SuperHero> {
    return this.http.post<SuperHero>(this.apiUrl, superHero);
  }

  updateSuperHero(superHero: SuperHero): Observable<SuperHero> {
    const url = `${this.apiUrl}/${superHero.id}`;
    return this.http.put<SuperHero>(url, superHero);
  }

  deleteSuperHero(id: number): Observable<void> {
    const url = `${this.apiUrl}/${id}`;
    return this.http.delete<void>(url);
  }
}
Step 4: Create the SuperHero model

Create a new file named super-hero.model.ts in the src/app folder.
Add the following code to define the SuperHero model:
typescript

export interface SuperHero {
  id: number;
  name: string;
  firstName: string;
  lastName: string;
  place: string;
}
Step 5: Generate components for CRUD operations

Generate components for listing, adding, editing, and deleting superheroes:
javascript

ng generate component super-hero-list
ng generate component super-hero-add
ng generate component super-hero-edit
ng generate component super-hero-delete
Step 6: Implement CRUD operations in the components

Open the super-hero-list.component.ts file and add the following code:

typescript

import { Component, OnInit } from '@angular/core';
import { SuperHero } from '../super-hero.model';
import { SuperHeroService } from '../super-hero.service';

@Component({
  selector: 'app-super-hero-list',
  templateUrl: './super-hero-list.component.html',
  styleUrls: ['./super-hero-list.component.css']
})
export class SuperHeroListComponent implements OnInit {
  superHeroes: SuperHero[] = [];

  constructor(private superHeroService: SuperHeroService) { }

  ngOnInit(): void {
    this.getSuperHeroes();
  }

  getSuperHeroes(): void {
    this.superHeroService.getSuperHeroes()
      .subscribe(superHeroes => this.superHeroes = superHeroes);
  }

  deleteSuperHero(id: number): void {
    this.superHeroService.deleteSuperHero(id)
      .subscribe(() => {
        this.superHeroes = this.superHeroes.filter(hero => hero.id !== id);
      });
  }
}
Similarly, implement the add, edit, and delete functionality in the super-hero-add.component.ts, super-hero-edit.component.ts, and super-hero-delete.component.ts files, respectively.

Step 7: Update the app component

Open the app.component.html file and replace its contents with the following code:
html

<h1>Superhero App</h1>
<router-outlet></router-outlet>
Step 8: Update the routing

Open the app-routing.module.ts file and replace its contents with the following code:
typescript

import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { SuperHeroListComponent } from './super-hero-list/super-hero-list.component';
import { SuperHeroAddComponent } from './super-hero-add/super-hero-add.component';
import { SuperHeroEditComponent } from './super-hero-edit/super-hero-edit.component';
import { SuperHeroDeleteComponent } from './super-hero-delete/super-hero-delete.component';

const routes: Routes = [
  { path: '', component: SuperHeroListComponent },
  { path: 'add', component: SuperHeroAddComponent },
  { path: 'edit/:id', component: SuperHeroEditComponent },
  { path: 'delete/:id', component: SuperHeroDeleteComponent },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
Step 9: Update the app module

Open the app.module.ts file and import the necessary modules:
typescript

import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from './app-routing.module';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { SuperHeroListComponent } from './super-hero-list/super-hero-list.component';
import { SuperHeroAddComponent } from './super-hero-add/super-hero-add.component';
import { SuperHeroEditComponent } from './super-hero-edit/super-hero-edit.component';
import { SuperHeroDeleteComponent } from './super-hero-delete/super-hero-delete.component';

@NgModule({
  declarations: [
    AppComponent,
    SuperHeroListComponent,
    SuperHeroAddComponent,
    SuperHeroEditComponent,
    SuperHeroDeleteComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
Step 10: Update the HTML templates

Update the HTML templates for the components as per your desired design and functionality.
Step 11: Run the app

In the terminal, navigate to the root folder of your Angular app (superhero-app).
Run the following command to start the development server:

ng serve
Open your browser and visit http://localhost:4200 to see and interact with your SuperHero CRUD app.
That's it! You now have an Angular app that performs CRUD operations on the SuperHero model. You can further enhance the app by adding validation, error handling, confirmation dialogs, and additional features as per your requirements.