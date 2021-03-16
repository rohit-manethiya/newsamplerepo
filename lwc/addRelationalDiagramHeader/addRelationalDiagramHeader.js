/* eslint-disable no-console */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/copadoCorePubsub';

// Import the URL for the static resource
import DTS_IMAGES from '@salesforce/resourceUrl/DTS_images';

// Import custom labels
import relationshipDiagram from '@salesforce/label/c.Relationship_Diagram';
import refreshDiagram from '@salesforce/label/c.Refresh_Diagram';

export default class AddRelationalDiagramHeader extends LightningElement {
    @api templateName;
    @wire(CurrentPageReference) pageRef;

    // Expose the static resource URL to use in the template.
    iconImageUrl = DTS_IMAGES + '/app_icon.png';

    // Expose the labels to use in the template.
    label = {
        relationshipDiagram,
        refreshDiagram
    };

    handleRefreshDiagram(event) {
        fireEvent(this.pageRef, 'refreshDiagramClicked', event.target.value);
    }
}