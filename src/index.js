const counter = document.querySelector(".counter-number");
async function updateCounter() {
  let response = await fetch("https://3xuycln7dlbwozoufmfgknl6ri0ohmmv.lambda-url.us-east-1.on.aws/");
  let data = await response.json();
  counter.innerHTML = `${data} People have Visited this Site`;
}

updateCounter();