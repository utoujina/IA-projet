const cards = document.querySelectorAll('.card');
const cases = document.querySelectorAll('.case');


// Déséllectionne les élément sauf celui en paramètre
function deselectExcept(selectedElement, elements) {
    elements.forEach(element => {
        if (element !== selectedElement) {
            element.classList.remove('selected');
        }
    });
}

// Event pour les cartes
cards.forEach(card => {
    card.addEventListener('click', () => {
        deselectExcept(card, cards);
        card.classList.toggle('selected');
        indisponnible_case();
    });
});

// Event pour les cases
cases.forEach(caseElement => {
    caseElement.addEventListener('click', () => {
        deselectExcept(caseElement, cases);
        caseElement.classList.toggle('selected');
        
    });
});

// envent pour couloir indisponnible
function indisponnible_case() {
    const card_selected = document.querySelector('.card.selected');
    
    if (card_selected) {
        const card_value = card_selected.querySelector('.value').getAttribute('value');
        const current_case2 = JSON.parse(current_case);
        const caseDispo = get_available_case(current_case2, card_value);
        
        cases.forEach(caseElement => {
            const case_col = caseElement.querySelector('.value');
            const value_case_col = case_col.getAttribute('value');

            if (!caseDispo.includes(parseInt(value_case_col))) {
                caseElement.classList.add('unactionable');
                caseElement.classList.remove('selected');
                
            } else {
                caseElement.classList.remove('unactionable');
            }
        });
    }
}

// Fonction du bouton d'envoie
function submit_player_choice() {
    const card_selected = document.querySelector('.card.selected');
    const case_selected = document.querySelector('.case.selected');
    
    var button_suivant = document.getElementById('button_suivant');
    var button_submit = document.getElementById('button_submit');

    // Vérifier si une carte et une case sont sélectionnées
    if (card_selected && case_selected) {
        
        var card_value = card_selected.querySelector('.value').getAttribute('value');
        var case_value = case_selected.querySelector('.value').getAttribute('value');
        
        // Envoyer les éléments sélectionnés au backend via une requête Fetch
        var formData = new FormData();
        formData.append('card', card_value);
        formData.append('case', case_value);
        
        fetch('/Human_choice', {
            method: 'POST',
            body: formData
        })
        .then((response) => response.json())
        .then((data) => {
            console.log(data);
        })
        .catch((error) => {
            console.log(error);
        });
        
        // Mettre à jour les boutons
        button_suivant.style.pointerEvents = 'auto';
        button_submit.style.pointerEvents = 'none';
        button_suivant.style.opacity = "1";
        button_submit.style.opacity = "0.5";
        
        case_chosen = null;
        if (case_value == 0) {
            case_chosen = "gauche";
        }
        if (case_value == 1){
            case_chosen = "milieu";
        }
        if(case_value == 2){
            case_chosen = "droite";
        }
        
        displayMessage("TBot : Vous avez choisit de déplacer votre joueur de " + card_value + " secondes et de le placer sur la case " + case_chosen +" .");
    }
    else{
        alert("Veuillez sélectionner une carte et une case.");
    }
}

// Fonction renvoyant la liste des couloir disponibles
function get_available_case(box, card) {
    let box_to_reach = box[0] + card;
    let available_cases = [];
    
    if (card === 1) {
        if (box[1] === 0) {
            available_cases.push(0, 1);
        } else if (box[1] === 2) {
            available_cases.push(1, 2);
        } else if (box[1] === 1) {
            available_cases.push(0, 1, 2);
        }
    } else {
        if (box_to_reach > 0 && box_to_reach < 11) {
            available_cases.push(0, 1, 2);
        } else if (box_to_reach > 10 && box_to_reach < 19) {
            available_cases.push(0, 2);
        } else if (box_to_reach > 18 && box_to_reach < 22) {
            available_cases.push(0, 1, 2);
        } else if (box_to_reach > 21 && box_to_reach < 36) {
            if (box[0] < 22) {
                available_cases.push(0, 1, 2);
            } else {
                if (box[1] === 2) {
                    available_cases.push(2);
                } else {
                    available_cases.push(0, 1);
                }
            }
        } else if (box_to_reach > 35 && box_to_reach < 73) {
            available_cases.push(0, 2);
        } else if (box_to_reach > 72 && box_to_reach < 76) {
            available_cases.push(0);
        } else if (box_to_reach > 75 && box_to_reach < 85) {
            available_cases.push(0, 2);
        } else if (box_to_reach > 84 && box_to_reach < 95) {
            if (box[0] < 84) {
                available_cases.push(0, 2);
            } else {
                available_cases.push(box[1]);
            }
        } else if (box_to_reach > 94 && box_to_reach < 106) {
            available_cases.push(0, 1, 2);
        }
    }
    
    return available_cases;
}