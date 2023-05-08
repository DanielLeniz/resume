const { defineConfig } = require("cypress");


module.exports = defineConfig({
  projectId: 'brccth',
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
  env: {
    API_URL: 'https://p2gv3ro832.execute-api.us-east-1.amazonaws.com/dev/get-resume'

  },
  component: {
    specPattern: 'backend/*.cy.{js,jsx,ts,tsx}'
  }
});
