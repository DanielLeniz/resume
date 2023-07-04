const counter = document.querySelector(".counter-number");
async function updateCounter() {
  let response = await fetch("https://tz30e61t47.execute-api.us-east-1.amazonaws.com/dev/get_resume");
  let data = await response.json();
  counter.innerHTML = `You are visitor number <span style='color:rgb(190, 78, 78)'> ${data}</span>`;
}

updateCounter();