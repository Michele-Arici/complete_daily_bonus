const { ref } = Vue;

const app = Vue.createApp({
    data() {
        return {
            displayUi: false,
            rouletteData: [],
            duplicatedData: [],
            firstElement: 0,
            probability: {},
            lastIds: [],
        };
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.type === "dailyBonus") {
                if (event.data.action === "initialize") {
                    console.log("initialize");
                    this.probability = event.data.probability;
                    this.rouletteData = JSON.parse(event.data.rouletteData);
                    
                } else if (event.data.action === "open") {
                    this.displayUi = true;
                    
                    // wait vue to render
                    this.$nextTick(()=>{
                        this.initializeDisplayItems();
                        this.initializeRoulette();
                    })
                } else if (event.data.action === "close") {
                    this.displayUi = false;
                } else if (event.data.action === "setData") {
                    eval(`this.${event.data.setting} = "${event.data.value}"`);
                }
            }
        });

        window.addEventListener("keyup", (event) => {
            if (event.key === "Escape") {
                this.closeSettings();
            }
        });
    },
    methods: {
        openSettings() {
            $("#settings-modal").modal("show");
        },
        closeSettings() {
            $("#settings-modal").modal("hide");
            $.post('https://complete_daily_bonus/close');
        },
        initializeDisplayItems() {
            var display = document.getElementById("displayItems");

            this.rouletteData.forEach((item) => {
                const colDiv = document.createElement("div");
                colDiv.classList.add("col");
                const itemDiv = document.createElement("div");
                itemDiv.classList.add(item.rarity);
                itemDiv.classList.add("img-responsive");
                itemDiv.classList.add("img-responsive-1x1");
                itemDiv.classList.add("rounded");
                itemDiv.classList.add("border");
                itemDiv.style.backgroundImage = `url(${item.img})`;
                itemDiv.style.backgroundSize = "contain";
                itemDiv.style.display = "flex";
                itemDiv.style.alignItems = "flex-end";
                itemDiv.style.position = "relative";
                itemDiv.style.justifyContent = "center";
                itemDiv.style.boxShadow = "inset 0px -57px 73px -28px rgb(0 0 0 / 85%)";

                const h3 = document.createElement("h3");
                h3.classList.add("text-center");
                h3.classList.add("text-white");
                h3.classList.add("text-shadow");
                h3.classList.add("text-uppercase");

                h3.style.position = "absolute";
                h3.style.marginBottom = "0.5rem";
                h3.style.fontWeight = "800";
                h3.style.lineHeight = "1.2";
                h3.innerText = item.name;
                itemDiv.appendChild(h3);

                colDiv.appendChild(itemDiv);
                display.appendChild(colDiv);
            });
        },
        createItemCard(item) {
            var itemDiv = document.createElement("div");
            var svg = `<svg class="rouletteCard-svg ${item.rarity}-svg" version="1.1" xmlns="http://www.w3.org/2000/svg" width="174" height="200" viewBox="0 0 173.20508075688772 200" stroke-width="2px">
                <defs>
                    <pattern id="image_${item.id}" x="0" y="0" patternUnits="userSpaceOnUse" height="11rem" width="100%">
                        <image x="0" y="0" xlink:href="${item.img}" height="11rem" width="100%" preserveAspectRatio="xMidYMid meet"/>
                    </pattern>
                    <linearGradient id='gradient-legendary' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='0%' stop-color='#7a4a0f'/>
                        <stop offset='100%' stop-color='#f5b942fd'/>
                    </linearGradient>
                    <linearGradient id='gradient-epic' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='0%' stop-color='#520966'/>
                        <stop offset='100%' stop-color='#c368dcfd'/>
                    </linearGradient>
                    <linearGradient id='gradient-rare' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='0%' stop-color='#001935fd'/>
                        <stop offset='100%' stop-color='#4a9dfdfd'/>
                    </linearGradient>
                    <linearGradient id='gradient-common' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='0%' stop-color='#4a4a4a'/>
                        <stop offset='100%' stop-color='#ffffff'/>
                    </linearGradient>
                </defs>
                <path class="${item.rarity}-svg-path" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                <path fill="url(#image_${item.id})" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
            </svg>`;
            itemDiv.innerHTML = svg;

            return itemDiv;
        },
        initializeRoulette() {
            var data = this.rouletteData;

            const numCopies = this.rouletteData.length * 2;

            const duplicatedData = [];

            while (duplicatedData.length < numCopies * this.rouletteData.length) {
                // generete an item randomly based on probability
                const rand = Math.random();
                let cumulativeProbability = 0;

                for (const key in this.probability) {
                    cumulativeProbability += this.probability[key];
                    if (rand <= cumulativeProbability) {
                        const rarity = key;
                        const items = data.filter(item => item.rarity === rarity);
                        const selectedItem = items[Math.floor(Math.random() * items.length)];
                        duplicatedData.push(selectedItem);
                        break;
                    }
                }
            }

            duplicatedData.sort(() => Math.random() - 0.5);
            data = duplicatedData;
            this.duplicatedData = duplicatedData;

            const roulette = document.getElementById("rouletteItems");
            console.log(roulette);
            const itemsPerRow = this.rouletteData.length;

            var firstIds = [];
            var lastIds = [];
            for (let i = 0; i < data.length; i += itemsPerRow) {
                const row = document.createElement("div");
                row.classList.add("rowCard");

                const rowItems = data.slice(i, i + itemsPerRow);

                rowItems.forEach((item) => {
                    const itemDiv = this.createItemCard(item);
                    if (i == itemsPerRow) {
                        itemDiv.dataset.id = `${item.id}_first`;
                        firstIds.push(item.id);
                    } else if (i == data.length - itemsPerRow * 2 && !lastIds.includes(item.id)) {
                        itemDiv.dataset.id = `${item.id}_last`;
                        lastIds.push(item.id);
                    }
                    row.appendChild(itemDiv);
                });
                roulette.appendChild(row);
            }

            const selectedItemId = firstIds[Math.floor(Math.random() * firstIds.length)];
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_first"]`);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();
            console.log(selectedRect, rouletteRect, selectedElement, roulette);
            this.lastIds = lastIds;

            const moveDistance = rouletteRect.left - selectedRect.left + roulette.clientWidth / 2 - selectedRect.width / 2;

            roulette.style.transform = `translateX(${moveDistance}px)`;
            this.firstElement = this.getNumericTransformXValue(roulette);
        },
        getNumericTransformXValue(element) {
            const styles = window.getComputedStyle(element);
            const transformMatrix = new DOMMatrix(styles.transform);
            return transformMatrix.m41;
        },
        spinRoulette() {
            /*
            var selectedItem = null;
            var rarity = null;

            // get random rarity based on probability
            const rand = Math.random();            
            let cumulativeProbability = 0;

            for (const key in this.probability) {
                cumulativeProbability += this.probability[key];
                if (rand <= cumulativeProbability) {
                    rarity = key;
                    break;
                }
            }

            // get random item from rarity
            var data = this.rouletteData;
            var items = data.filter(item => item.rarity === rarity);
            selectedItem = items[Math.floor(Math.random() * items.length)];
            const selectedItemId = selectedItem.id;
            */

            // get a random item from lastIds
            const selectedItemId = this.lastIds[Math.floor(Math.random() * this.lastIds.length)];
            const selectedItem = this.rouletteData[selectedItemId];
            this.animateRoulette(selectedItem, selectedItemId);
        },
        animateRoulette(selectedItem, selectedItemId) {
            const roulette = document.getElementById("rouletteItems");
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_last"]`);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();
            const selectedWidth = selectedElement.offsetWidth / 2.3;

            // get a random value between -selectedWidth and selectedWidth
            const randomValue = Math.floor(Math.random() * selectedWidth) * (Math.round(Math.random()) ? 1 : -1)

            var moveDistance = rouletteRect.left - selectedRect.left + roulette.clientWidth / 2 - selectedRect.width / 2;
            moveDistance += randomValue;

            // disable button
            document.getElementById("spinButton").classList.add("disabled");
            document.getElementById("spinButton").classList.add("btn-loading");

            const id = `${selectedItemId}_last`;
                        
            gsap.to(roulette, {
                duration: 9,
                x: `${moveDistance}`,
                ease: "power4.out",
                onComplete: function() {
                    /*
                    // delete all items except ${selectedItemId}_last
                    const allItems = document.querySelectorAll(".rouletteCard");
                    allItems.forEach(item => {
                        if (item.dataset.id !== id) {
                            item.remove();
                        }
                    });

                    // remove div rowCard empty
                    const rowCards = document.querySelectorAll(".rowCard");
                    rowCards.forEach(row => {
                        if (row.innerHTML === "") {
                            row.remove();
                        }
                    });

                    // add h3 with item name to selected item
                    const winItem = document.querySelector(`[data-id="${id}"]`);
                    const h3 = document.createElement("h3");
                    h3.classList.add("text-center");
                    h3.classList.add("text-white");
                    h3.classList.add("text-shadow");
                    h3.classList.add("text-uppercase");
                    h3.style.position = "absolute";
                    h3.style.marginBottom = "0.5rem";
                    h3.style.fontWeight = "800";
                    h3.style.lineHeight = "1.2";
                    h3.innerText = selectedItem.name;
                    winItem.appendChild(h3);
                    */

                    // create item card and add it to modalBody
                    /*
                    const itemCard = document.createElement("div");
                    itemCard.classList.add("rouletteCard");
                    itemCard.classList.add(selectedItem.rarity);
                    itemCard.style.backgroundImage = `url(${selectedItem.img})`;
                    itemCard.style.backgroundSize = "contain";
                    itemCard.style.backgroundPosition = "center";
                    itemCard.style.backgroundRepeat = "no-repeat";
                    itemCard.alt = selectedItem.name;
                    itemCard.style.height = "10rem";
                    itemCard.style.width = "10rem";
                    itemCard.style.display = "flex";
                    itemCard.style.alignItems = "center";
                    itemCard.style.justifyContent = "center";
                    itemCard.style.position = "relative";
                    itemCard.style.boxShadow = "inset 0px -57px 73px -28px rgb(0 0 0 / 86%)";
                    
                    const h3 = document.createElement("h3");
                    h3.classList.add("text-center");
                    h3.classList.add("text-white");
                    h3.classList.add("text-shadow");
                    h3.classList.add("text-uppercase");
                    h3.style.position = "absolute";
                    h3.style.marginBottom = "0.1rem";
                    h3.style.fontWeight = "800";
                    h3.style.lineHeight = "1.2";
                    h3.innerText = selectedItem.name;
                    itemCard.appendChild(h3);
                    */

                    var itemDiv = document.createElement("div");
                    itemDiv.innerHTML = `
                    <h1 class="text-center text-white" style="margin-bottom: 0.5rem; font-weight: 700; font-weight: 1.7rem; filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.25));">Congratulations!</h1>
                    <svg class="rouletteCard-svg" style="height: 16rem; width: 16rem; position: relative; filter: drop-shadow(0px 0px 70px #fff);" version="1.1" xmlns="http://www.w3.org/2000/svg" width="174" height="200" viewBox="0 0 173.20508075688772 200" stroke="#ffffff8a" stroke-width="5px">
                        <defs>
                            <pattern id="image_${selectedItem.id}" x="0" y="0" patternUnits="userSpaceOnUse" height="11rem" width="100%">
                                <image x="0" y="0" xlink:href="${selectedItem.img}" height="11rem" width="100%" preserveAspectRatio="xMidYMid meet"/>
                            </pattern>
                            <linearGradient id='gradient-legendary' x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset='0%' stop-color='#7a4a0f'/>
                                <stop offset='100%' stop-color='#f5b942fd'/>
                            </linearGradient>
                            <linearGradient id='gradient-epic' x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset='0%' stop-color='#520966'/>
                                <stop offset='100%' stop-color='#c368dcfd'/>
                            </linearGradient>
                            <linearGradient id='gradient-rare' x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset='0%' stop-color='#001935fd'/>
                                <stop offset='100%' stop-color='#4a9dfdfd'/>
                            </linearGradient>
                            <linearGradient id='gradient-common' x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset='0%' stop-color='#4a4a4a'/>
                                <stop offset='100%' stop-color='#ffffff'/>
                            </linearGradient>
                        </defs>
                        <path class="${selectedItem.rarity}-svg-path" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                        <path fill="url(#image_${selectedItem.id})" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                    </svg>
                    <div class="text-center text-white text-muted" style="margin-top: 1rem;font-weight: 700; color: #838383!important; filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.25));">Item won:</div>
                    <h2 class="text-center text-white text-shadow" style="font-weight: 700; filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.25));">${selectedItem.name}</h2>`;                    

                    const modalBody = document.getElementById("modalBody");
                    modalBody.innerHTML = "";
                    modalBody.appendChild(itemDiv);

                    // opne rewar-modal
                    $("#reward-modal").modal("show");
                    document.querySelector(".modal-backdrop").style.zIndex = "-1";
                    
                    document.getElementById("spinButton").classList.remove("btn-loading");
                    document.getElementById("spinButton").innerText = "23:59:59";
                }
            });
        }        
    }
});

app.mount("#app");