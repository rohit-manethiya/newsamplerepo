import { LightningElement, api } from 'lwc';

export default class CopadocoreIllustration extends LightningElement {
    @api name;
    @api size;
    @api message;

    get imageClasses() {
        return `slds-size_${this.size}`;
    }

    get imageUrl() {
        return `/img/chatter/${this.name}.svg`;
    }
}