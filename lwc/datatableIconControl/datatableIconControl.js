import { LightningElement, api } from 'lwc';

export default class DatatableIconControl extends LightningElement {
    @api recordId;
    @api iconName;
    @api label;
    @api name;
    @api variant;
    @api alternativeText;
    @api size = 'small';

    handleClickAction() {
        this.dispatchEvent(
            new CustomEvent('iconclicked', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: { recordId: this.recordId },
                    action: {
                        name: 'iconclicked'
                    }
                }
            })
        );
    }
}