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
            lastClaimed: "24:00:00",
            canClaim: false,
            animationDuration: 10,
            isSpinning: false
        };
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.type === "dailyBonus") {
                if (event.data.action === "initialize") {
                    this.probability = event.data.probability;
                    this.rouletteData = JSON.parse(event.data.rouletteData);
                    this.animationDuration = event.data.animationDuration;
                } else if (event.data.action === "open") {
                    this.displayUi = true;
                    
                    // wait vue to render
                    this.$nextTick(()=>{
                        this.initializeDisplayItems();
                        this.initializeRoulette();
                    })
                } else if (event.data.action === "close") {
                    this.close();
                } else if (event.data.action === "setData") {
                    if (typeof event.data.value === "boolean") {
                        this[event.data.data] = event.data.value;
                    } else {
                        eval(`this.${event.data.data} = "${event.data.value}"`);
                    }
                }
            }
        });

        window.addEventListener("keyup", (event) => {
            if (event.key === "Escape") {
                this.close();
            }
        });
    },
    methods: {
        close() {
            this.duplicatedData = [];
            this.firstElement = 0;
            this.lastIds = [];
            document.getElementById("rouletteItems").innerHTML = "";
            document.getElementById("rouletteItems").style = "";
            document.getElementById("displayItems").innerHTML = "";

            this.displayUi = false;

            $.post('https://complete_daily_bonus/close');
        },
        sell(id) {
            document.getElementById("tablet").style.overflowY = "scroll";
            this.close();
            $.post('https://complete_daily_bonus/sell', JSON.stringify({id: id}));
        },
        reward(id) {
            document.getElementById("tablet").style.overflowY = "scroll";
            this.close();
            $.post('https://complete_daily_bonus/reward', JSON.stringify({id: id}));
        },
        initializeDisplayItems() {
            var display = document.getElementById("displayItems");
            display.innerHTML = "";

            // Temp array to order items by rarity
            var temp = [];
            for (const key in this.probability) {
                const items = this.rouletteData.filter(item => item.rarity === key);
                temp.push(...items);
            }

            // Sort the temp array by rarity (legendary, epic, rare, common)
            temp.sort((a, b) => {
                const rarityOrder = ['legendary', 'epic', 'rare', 'common'];
                return rarityOrder.indexOf(a.rarity) - rarityOrder.indexOf(b.rarity);
            });

            temp.forEach((item) => {
                const colDiv = document.createElement("div");
                colDiv.classList.add("col");

                const itemDiv = document.createElement("div");
                itemDiv.classList.add("display-card");
                itemDiv.classList.add(item.rarity);
                itemDiv.classList.add("img-responsive");
                itemDiv.classList.add("img-responsive-1x1");
                itemDiv.classList.add("rounded");
                itemDiv.classList.add("border");
                itemDiv.style.backgroundImage = `url(${item.img})`;

                const h3 = document.createElement("h3");
                h3.classList.add("text-white");
                h3.classList.add("text-shadow");
                h3.classList.add("item-card-title");
                h3.innerText = item.name;
                itemDiv.appendChild(h3);

                const span = document.createElement("span");
                span.classList.add("item-card-type");
                span.classList.add("text-shadow");
                const typeLabel = item.type.charAt(0).toUpperCase() + item.type.slice(1);
                span.innerText = `${typeLabel}`;
                itemDiv.appendChild(span);

                const probability = document.createElement("span");
                probability.classList.add("item-card-probability");
                probability.classList.add("text-shadow");
                probability.innerText = `%${this.probability[item.rarity] * 100}`;
                itemDiv.appendChild(probability);

                colDiv.appendChild(itemDiv);
                display.appendChild(colDiv);
            });
        },
        createItemCard(item) {
            var itemDiv = document.createElement("div");
            var svg = `<svg class="rouletteCard-svg ${item.rarity}-svg" version="1.1" xmlns="http://www.w3.org/2000/svg" width="174" height="200" viewBox="0 0 173.20508075688772 200" stroke-width="2px">
                <defs>
                    <pattern id="image_${item.id}" x="0" y="0" patternUnits="userSpaceOnUse" height="11rem" width="100%">
                        <image x="0" y="13" xlink:href="${item.img}" height="11rem" width="100%" preserveAspectRatio="xMidYMid meet"/>
                    </pattern>
                    <linearGradient id='gradient-legendary' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='30%' stop-color='#f5b942fd'/>
                        <stop offset='100%' stop-color='#7a4a0f'/>
                    </linearGradient>
                    <linearGradient id='gradient-epic' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='30%' stop-color='#c368dcfd'/>
                        <stop offset='100%' stop-color='#520966'/>
                    </linearGradient>
                    <linearGradient id='gradient-rare' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='30%' stop-color='#4a9dfdfd'/>
                        <stop offset='100%' stop-color='#001935fd'/>
                    </linearGradient>
                    <linearGradient id='gradient-common' x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset='30%' stop-color='#ffffff'/>
                        <stop offset='100%' stop-color='#4a4a4a'/>
                    </linearGradient>
                </defs>
                <path class="${item.rarity}-svg-path" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                <path fill="url(#image_${item.id})" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
            </svg>`;
            itemDiv.innerHTML = svg;

            return itemDiv;
        },
        initializeRoulette() {
            document.getElementById("rouletteItems").innerHTML = "";
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
                        if (items.length > 0) {                            
                            const selectedItem = items[Math.floor(Math.random() * items.length)];
                            duplicatedData.push(selectedItem);
                        }
                        break;
                    }
                }
            }

            duplicatedData.sort(() => Math.random() - 0.5);
            data = duplicatedData;
            this.duplicatedData = duplicatedData;

            const roulette = document.getElementById("rouletteItems");
            const itemsPerRow = this.rouletteData.length;

            var firstIds = [];
            var lastIds = [];
            var carBool = false;
            for (let i = 0; i < data.length; i += itemsPerRow) {
                const row = document.createElement("div");
                row.classList.add("rowCard");

                const rowItems = data.slice(i, i + itemsPerRow);

                rowItems.forEach((item) => {
                    if (item) {                        
                        const itemDiv = this.createItemCard(item);
                        if (i == itemsPerRow) {
                            itemDiv.dataset.id = `${item.id}_first`;
                            firstIds.push(item.id);
                        } else if (i == data.length - itemsPerRow * 2 && !lastIds.includes(item.id)) {
                            itemDiv.dataset.id = `${item.id}_last`;
                            lastIds.push(item.id);
                        }
                        if (i == data.length - itemsPerRow * 2 && !carBool) {
                            var car = this.rouletteData[1];
                            const carDiv = this.createItemCard(car);
                            carDiv.dataset.id = `1_last`;
                            lastIds.push(1)
                            row.appendChild(carDiv);
                            carBool = true;
                        }
                        row.appendChild(itemDiv);
                    }
                });
                roulette.appendChild(row);
            }

            const selectedItemId = firstIds[Math.floor(Math.random() * firstIds.length)];
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_first"]`);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();

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
            if (this.canClaim === false) { return; }

            // get a random item from lastIds
            //const selectedItemId = this.lastIds[Math.floor(Math.random() * this.lastIds.length)];
            const selectedItemId = 1;
            const selectedItem = this.rouletteData[selectedItemId];

            $.post("https://complete_daily_bonus/claim");
            
            this.animateRoulette(selectedItem, selectedItemId);
        },
        animateRoulette(selectedItem, selectedItemId) {
            this.isSpinning = true;
            const roulette = document.getElementById("rouletteItems");
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_last"]`);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();
            const selectedWidth = selectedElement.offsetWidth / 2.3;

            // get a random value between -selectedWidth and selectedWidth
            const randomValue = Math.floor(Math.random() * selectedWidth) * (Math.round(Math.random()) ? 1 : -1)

            var moveDistance = rouletteRect.left - selectedRect.left + roulette.clientWidth / 2 - selectedRect.width / 2;
            moveDistance += randomValue;
            
            var ref = this;

            var anim = gsap.context(() => {
                gsap.to(roulette, {
                    duration: ref.animationDuration,
                    x: `${moveDistance}`,
                    ease: "power4.out",
                    onComplete: function() {
                        ref.isSpinning = false;
                        // remove overflow from tablet
                        document.getElementById("tablet").style.overflow = "hidden";

                        var itemDiv = document.createElement("div");
                        itemDiv.innerHTML = `
                        <h1 class="text-center text-white congratulations-text">Congratulations!</h1>
                        <svg class="item-won-svg item-won-shadow-${selectedItem.rarity} ${selectedItem.rarity}-svg" version="1.1" xmlns="http://www.w3.org/2000/svg" width="174" height="200" viewBox="0 0 173.20508075688772 200" stroke-width="3px">
                            <defs>
                                <pattern id="image_${selectedItem.id}" x="0" y="0" patternUnits="userSpaceOnUse" height="11rem" width="100%">
                                    <image x="0" y="0" xlink:href="${selectedItem.img}" height="11rem" width="100%" preserveAspectRatio="xMidYMid meet"/>
                                </pattern>
                                <linearGradient id='gradient-legendary' x1="0%" y1="0%" x2="0%" y2="100%">
                                    <stop offset='30%' stop-color='#f5b942fd'/>
                                    <stop offset='100%' stop-color='#7a4a0f'/>
                                </linearGradient>
                                <linearGradient id='gradient-epic' x1="0%" y1="0%" x2="0%" y2="100%">
                                    <stop offset='30%' stop-color='#c368dcfd'/>
                                    <stop offset='100%' stop-color='#520966'/>
                                </linearGradient>
                                <linearGradient id='gradient-rare' x1="0%" y1="0%" x2="0%" y2="100%">
                                    <stop offset='30%' stop-color='#4a9dfdfd'/>
                                    <stop offset='100%' stop-color='#001935fd'/>
                                </linearGradient>
                                <linearGradient id='gradient-common' x1="0%" y1="0%" x2="0%" y2="100%">
                                    <stop offset='30%' stop-color='#ffffff'/>
                                    <stop offset='100%' stop-color='#4a4a4a'/>
                                </linearGradient>
                            </defs>
                            <path class="${selectedItem.rarity}-svg-path" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                            <path fill="url(#image_${selectedItem.id})" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path>
                        </svg>
                        <div class="text-center mt-2">Item won:</div>
                        <h2 class="text-center text-white text-shadow item-won-name">${selectedItem.name}</h2>`;                    
    
                        const modalBody = document.getElementById("modalBody");
                        modalBody.innerHTML = "";
                        modalBody.appendChild(itemDiv);
    
                        const modalFooter = document.getElementById("modalFooter");
                        modalFooter.innerHTML = `
                            <button id="sell" type="button" class="btn btn-danger text-uppercase item-won-sell" data-bs-dismiss="modal">Sell for $${selectedItem.sell}</button>
                            <button id="collect" type="button" class="btn btn-primary text-uppercase item-won-collect" data-bs-dismiss="modal">Collect</button>
                        `;
    
                        // Add event listeners to the buttons
                        const sellButton = document.getElementById("sell");
                        sellButton.addEventListener("click", () => {
                            ref.sell(selectedItem.id);
                        });
    
                        const collectButton = document.getElementById("collect");
                        collectButton.addEventListener("click", () => {
                            ref.reward(selectedItem.id);
                        });
    
                        // open reward-modal
                        $("#reward-modal").modal("show");
                        document.querySelector(".modal-backdrop").style.display = "none";
                        
                        anim.revert();
                    }
                });
            });
            return () => anim.revert();
        }        
    }
});

app.mount("#app");