const session = pl.create();

session.consult("./static/prolog/tbot.pl");

function askQuestion(question) {
    
    // Suppresion des apostrophes
    let inputSansApostrophes = question.replace(/'/g, ' ');
    pl_query = "tour2france([" + inputSansApostrophes.split(' ').map(mot => '\'' + mot + '\'').join(',') + "], Reponse).";
    session.query(pl_query);
    console.log(pl_query);
    
    displayMessage("Vous : " + question);
    session.answer(x => {
        console.log(x);
        var answer = x.links.Reponse;
        console.log(answer);
        displayMessage("TBot : " + answer);
    });
}

function displayMessage(message) {

    var messages = document.getElementById("messages");
    var div = document.createElement("div");

    div.textContent = message.trim();
    messages.appendChild(div);
    messages.scrollTop = messages.scrollHeight;
}

document.getElementById("message-form").addEventListener("submit", function(event) {
    event.preventDefault();
    var question = document.getElementById("message-input").value.trim();
    if (question !== "") {
       
        askQuestion(question);
        document.getElementById("message-input").value = "";
    }
});
