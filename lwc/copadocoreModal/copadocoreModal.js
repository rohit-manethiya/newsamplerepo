import { LightningElement, api } from 'lwc';

export default class CopadocoreModal extends LightningElement {
    @api hideClose;

    @api size = 'x-small';
    get modalClasses() {
        return `slds-modal slds-fade-in-open slds-modal_${this.size}`;
    }

    showModal;
    @api show() {
        this.showModal = true;
    }
    @api hide() {
        this.showModal = false;
    }

    handleClose() {
        this.hide();
    }

    showTitleContainer() {
        const titleContainer = this.template.querySelector('[data-id="titleContainer"]');
        titleContainer.classList.remove('slds-hide');
    }

    handleTitleChange() {
        if (this.showModal) {
            this.showTitleContainer();

            const title = this.template.querySelector('[data-id="title"]');
            title.classList.remove('slds-hide');
        }
    }

    handleTaglineChange() {
        if (this.showModal) {
            this.showTitleContainer();

            const tagline = this.template.querySelector('[data-id="tagline"]');
            tagline.classList.remove('slds-hide');
        }
    }

    handleFooterChange() {
        if (this.showModal) {
            const footer = this.template.querySelector('[data-id="footer"]');
            footer.classList.remove('slds-hide');
        }
    }
}