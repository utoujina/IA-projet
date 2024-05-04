const session = pl.create();

session.consult("./static/prolog/tbot.pl");

function askQuestion(question) {
    
    // Suppresion des apostrophes dans la question
    let inputSansApostrophes = question.replace(/'/g, ' ');
    // Construction de la query, c'est juste un gros string
    pl_query = "tour2france([" + inputSansApostrophes.split(' ').map(mot => '\'' + mot + '\'').join(',') + "], Reponse).";
    session.query(pl_query);
    console.log(pl_query);
    
    // Fonction d'affichage de la question
    displayMessage("Vous : " + question);
    
    // Récup de la réponse prolog
    session.answer(x => {
        console.log(x);
        var answer = x.links.Reponse;
        console.log(answer);
        // fonction d'affichage de la réponse
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
