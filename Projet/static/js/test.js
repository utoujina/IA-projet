const session = pl.create();


session.consult("./static/prolog/test.pl");

function askQuestion(question) {
        session.query("repondre('" + question + "', Reponse).");
        
        session.answer(x => {
        var answer = x.lookup("Reponse");
        displayMessage("Vous : " + question);
        displayMessage("TBot : " + answer);
    });
}

function extractMessageFromList(message) {
   
    // Supprimer les espaces et les caractères spéciaux au début et à la fin de la chaîne
    var trimmedStr = message.trim();
   
    if (trimmedStr.startsWith("TBot :")) {
        // Extraire le message après "TBot :" en supprimant les premiers 6 caractères
        var message = trimmedStr.slice(6);

        // Supprimer les crochets
        var messageSansCrochets = message.slice(2,-1);

        // Séparer les caractères en un tableau
        var caracteres = messageSansCrochets.split(',');

        // Assembler les caractères en une chaîne
        var message = caracteres.join('');

        return "TBot : "+ message;
    } else {
        return message;
    }
}



function displayMessage(message) {


    var messages = document.getElementById("messages");
    var div = document.createElement("div");


    div.textContent = extractMessageFromList(message);
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
