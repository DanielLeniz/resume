import rgbHex from 'rgb-hex';

describe('Test homepage content', () => 
  //Loads page and checks for expected word
  it('Finds the words "Projects"', ()=>{
      cy.visit("https://danielleniz.com")
      cy.contains("Projects")
  })
)
  it('Checks for Visitor Counter', {defaultCommandTimeout: 10000}, ()=>{
    cy.visit('https://danielleniz.com')
    //Checks vistor counter text displays
    cy.contains('You are visitor')
    //Checks that visitor count is integer
    cy.get('[class=counter-number]')
    .invoke('text')
    .should('match', /[^0-9]*$/)
  })
  
  //Finds element and checks it matches expected hex code 
  it('Checks background color', () => {
    cy.visit('https://danielleniz.com')
    cy.get('[id=footer]')
    .invoke('css', 'background-color')
    .then((bgcolor) => {
      expect(rgbHex(bgcolor)).to.eq('618063')
    })
  })

  it('Checks counter increments', () => {
    //Call the API once and wrap / store the result as var 'count'
    cy.request({
      method:'POST', 
      url: Cypress.env('API_URL') 
    })
    .then((response) =>{
      let count = Number(response.body);
      cy.wrap(count).as('count')
    })
    
    //Call it again and wrap / store the result as var 'new_count'
    cy.request({
      method:'POST', 
      url: Cypress.env('API_URL')
    })
    .then((response) =>{
      let new_count = Number(response.body);
      cy.wrap(new_count).as('new_count')
    })
    
    //'get' the var 'count' then get 'new_count' within the new function
    cy.get('@count').then(count => {
      cy.get('@new_count').should('be.gt', count);
    })
  })
  

