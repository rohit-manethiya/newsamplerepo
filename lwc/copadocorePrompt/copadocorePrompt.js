import { LightningElement, api } from 'lwc';

export default class CopadocorePrompt extends LightningElement {
    @api title;
    @api message;
    @api buttonLabel;
    @api variant;

    themeClass;

    connectedCallback() {
        this.themeClass = `slds-modal__header slds-theme_${this.variant} slds-theme_alert-texture`;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('promptclose'));
    }
}