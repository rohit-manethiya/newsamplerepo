/* eslint-disable no-console */
/* global vis */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';

// Import the apex class methods
import getMainTemplateAttachment from '@salesforce/apex/ADD_DependencyHandler.getMainTemplateAttachment';
import getNamespace from '@salesforce/apex/ADD_DependencyHandler.getNamespace';

// Import the URL for the static resource
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import DTS_IMAGES from '@salesforce/resourceUrl/DTS_images';
import VIS from '@salesforce/resourceUrl/VisJavascript';

// Import custom labels
import childRelationship from '@salesforce/label/c.Child_Relationship';
import parentRelationship from '@salesforce/label/c.Parent_Relationship';
import legend from '@salesforce/label/c.Legend';
import hasFilter from '@salesforce/label/c.Has_Filters';
import willDeployAttachments from '@salesforce/label/c.Will_Deploy_Attachments';

export default class AddRelationalDiagram extends NavigationMixin(LightningElement) {
    @api recordIdFromParent;
    @wire(CurrentPageReference) pageRef;
    relationsResult;
    mainTemplateName;

    // Expose URL of assets included inside an archive file
    arrowMaster = DTS_IMAGES + '/arrow-parent.svg';
    arrowChild = DTS_IMAGES + '/arrow-child.svg';

    // Expose the labels to use in the template.
    label = {
        childRelationship,
        parentRelationship,
        legend,
        hasFilter,
        willDeployAttachments
    };

    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    navigateToDataTemplateRecord(recordId) {
        getNamespace({ templateIdsList: this.recordIdFromParent })
            .then(result => {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        objectApiName: `${result}Data_Template__c`,
                        actionName: 'view'
                    }
                }).then(url => {
                    window.open(url, '_blank');
                });
            })
            .catch(error => {
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });
    }

    sendTemplateNameEvent(templateName) {
        const selectedEvent = new CustomEvent('populatetemplatename', {
            detail: templateName
        });

        this.dispatchEvent(selectedEvent);
    }

    initializeVIS() {
        const self = this;
        let nodeArray = [];
        let edges = [];

        // parse the string result
        const parsedData = JSON.parse(self.relationsResult);

        // create an array with nodes
        parsedData.relationshipDiagramWrappers.forEach(nodeItem => {
            let node = {};

            // populate mainTemplateName variable to send to parent and than header lwc
            if (nodeItem.isMainTemplate) {
                self.mainTemplateName = nodeItem.dataTemplateName;
            }

            // to show attachment icon check template attachment options
            // checking nodeItem.templateAttachmentOption === null, because if user select none from dropdown, the value is coming null
            const templateAttachmentOptions =
                nodeItem.templateAttachmentOption === null || nodeItem.templateAttachmentOption === 'No Attachments' ? 'none' : 'block';

            // to show filter icon check template filters
            let templateFilters = 'none';
            nodeItem.queryFilterList.forEach(filterItem => {
                if (filterItem.finalValue !== '') {
                    templateFilters = 'block';
                }
            });

            const backgroundColorOfSvg = nodeItem.isMainTemplate ? '#FFFFFF' : '#EFEFF0';
            const borderColorOfSvg = nodeItem.isMainTemplate ? '#0849A2' : '#1589EE';

            // replace all special characters from template name with empty space
            const templateName = nodeItem.dataTemplateName.replace(/[^a-zA-Z ]/g, ' ');

            let svgNode =
                `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="200">` +
                `<style>` +
                `.nodeHeader { font: 36px Arial; }` +
                `.nodeSubHeader { font: 32px Arial; }` +
                `</style>` +
                `<rect width="800" height="200" stroke="${borderColorOfSvg}" stroke-width="8" fill="${backgroundColorOfSvg}" rx="30" />` +
                `<text x="30" y="60" class="nodeHeader" fill="#2e82e0" stroke="none">` +
                `${templateName}` +
                `</text>` +
                `<text x="30" y="110" class="nodeSubHeader" fill="#16325C" stroke="none">` +
                `${nodeItem.templateMainObject}` +
                `</text>` +
                // filter icon svg
                `<svg xmlns="http://www.w3.org/2000/svg" x="650" y="130" width="45" height="45" viewBox="0 0 172 172" style=" fill:#000000;">` +
                `<g fill="none" fill-rule="nonzero" stroke="none" stroke-width="1" stroke-linecap="butt" stroke-linejoin="miter" stroke-miterlimit="10" stroke-dasharray="" stroke-dashoffset="0" font-family="none" font-weight="none" font-size="none" text-anchor="none" style="mix-blend-mode: normal" display="${templateFilters}">` +
                `<path d="M0,172v-172h172v172z" fill="none"></path>` +
                `<g fill="#2E82E0">` +
                `<path d="M13.76,6.88c-2.06937,0 -3.44,1.37063 -3.44,3.44v10.32c0,1.03469 0.38969,1.67969 1.075,2.365l55.04,58.48c0.68531,0.68531 1.67969,1.075 2.365,1.075h34.4c1.03469,0 1.67969,-0.38969 2.365,-1.075l55.04,-58.48c0.68531,-0.68531 1.075,-1.33031 1.075,-2.365v-10.32c0,-2.06937 -1.37062,-3.44 -3.44,-3.44zM65.36,89.44v51.6c0,1.37063 0.68531,2.43219 1.72,3.1175l34.4,20.64c0.34938,0.34938 1.03469,0.3225 1.72,0.3225c0.68531,0 1.03469,0.02688 1.72,-0.3225c1.03469,-0.68531 1.72,-1.74687 1.72,-3.1175v-72.24z"></path>` +
                `</g>` +
                `</g>` +
                `</svg>` +
                // attachment icon svg
                `<svg xmlns="http://www.w3.org/2000/svg" x="725" y="130" width="45" height="45" viewBox="0 0 172 172" style=" fill:#000000;">` +
                `<g fill="none" fill-rule="nonzero" stroke="none" stroke-width="1" stroke-linecap="butt" stroke-linejoin="miter" stroke-miterlimit="10" stroke-dasharray="" stroke-dashoffset="0" font-family="none" font-weight="none" font-size="none" text-anchor="none" style="mix-blend-mode: normal" display="${templateAttachmentOptions}">` +
                `<path d="M0,172v-172h172v172z" fill="none"></path>` +
                `<g fill="#2E82E0">` +
                `<path d="M78.83333,7.16667c-15.74756,0 -28.66667,12.91911 -28.66667,28.66667v89.58333c0,21.6833 17.73337,39.41667 39.41667,39.41667c21.6833,0 39.41667,-17.73336 39.41667,-39.41667v-82.41667h-14.33333v82.41667c0,13.93503 -11.1483,25.08333 -25.08333,25.08333c-13.93503,0 -25.08333,-11.1483 -25.08333,-25.08333v-89.58333c0,-8.00277 6.33056,-14.33333 14.33333,-14.33333c8.00277,0 14.33333,6.33056 14.33333,14.33333v75.25c0,2.05638 -1.52695,3.58333 -3.58333,3.58333c-2.05638,0 -3.58333,-1.52695 -3.58333,-3.58333v-68.08333h-14.33333v68.08333c0,9.81162 8.10505,17.91667 17.91667,17.91667c9.81162,0 17.91667,-8.10505 17.91667,-17.91667v-75.25c0,-15.74756 -12.91911,-28.66667 -28.66667,-28.66667z"></path>` +
                `</g>` +
                `</g>` +
                `</svg>` +
                `</svg>`;

            // define each node options
            let url = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svgNode);

            node = {
                id: nodeItem.dataTemplateId,
                image: url,
                shape: 'image'
            };

            // create an array with edges
            nodeItem.edges.forEach(edgeItem => {
                let edge = {};
                // define each edge options
                edge = {
                    from: edgeItem.fromTemplateId,
                    to: edgeItem.toTemplateId,
                    color: {
                        color: edgeItem.relationshipType === 'child' ? '#1589EE' : '#BA99DE',
                        highlight: edgeItem.relationshipType === 'child' ? '#1589EE' : '#BA99DE',
                        hover: edgeItem.relationshipType === 'child' ? '#1589EE' : '#BA99DE'
                    },
                    length: 250,
                    arrows: {
                        to:
                            edgeItem.relationshipType === 'child'
                                ? {
                                      enabled: true,
                                      src: self.arrowChild,
                                      type: 'image',
                                      imageWidth: 17,
                                      imageHeight: 17
                                  }
                                : {},
                        from:
                            edgeItem.relationshipType === 'parent'
                                ? {
                                      enabled: true,
                                      src: self.arrowMaster,
                                      type: 'image',
                                      imageWidth: 17,
                                      imageHeight: 17
                                  }
                                : {}
                    },
                    smooth: {
                        type: 'horizontal',
                        roundness: 1
                    },
                    width: 2,
                    fixed: true
                };
                edges.push(edge);
            });
            nodeArray.push(node);
        });

        // create a network
        const container = self.template.querySelector('.relationship-diagram');
        let nodes = new vis.DataSet(nodeArray);

        const data = {
            nodes: nodes,
            edges: edges
        };

        const maximumScale = 1.6;
        const minimumScale = 0.5;
        const defaultScale = 1.3;

        const defaultviewlimit = {
            scale: defaultScale
        };
        const afterzoomlimit = {
            scale: maximumScale
        };
        const beforezoomlimit = {
            scale: minimumScale
        };

        // populate the options for network
        const options = {
            clickToUse: false,
            autoResize: true,
            interaction: {
                navigationButtons: true,
                keyboard: {
                    enabled: true
                },
                hover: true
            },
            physics: {
                barnesHut: {
                    gravitationalConstant: -30000,
                    avoidOverlap: 1
                },
                minVelocity: 0.75
            }
        };

        // draw the network
        const network = new vis.Network(container, data, options);
        self.sendTemplateNameEvent(self.mainTemplateName);

        network.on('select', function(properties) {
            const ids = properties.nodes;

            if (ids[0]) {
                self.navigateToDataTemplateRecord(ids[0]);
            }
        });

        network.on('stabilizationIterationsDone', function() {
            network.moveTo(defaultviewlimit);
            network.setOptions({ physics: false });
        });

        network.on('zoom', function() {
            if (network.getScale() >= maximumScale) {
                network.moveTo(afterzoomlimit);
            } else if (network.getScale() <= minimumScale) {
                network.moveTo(beforezoomlimit);
            }
        });
    }

    handleLoad() {
        getMainTemplateAttachment({ templateIdsList: this.recordIdFromParent })
            .then(result => {
                this.relationsResult = result;
                if (this.relationsResult) {
                    if (this.relationsResult.processStatus === 'Error') {
                        this.showToastMessage('Application Error', this.relationsResult.processMessage, 'error', 'dismissable');
                    } else {
                        this.initializeVIS();
                    }
                }
            })
            .catch(error => {
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });
    }

    connectedCallback() {
        Promise.all([loadScript(this, VIS + '/copado-visjs/visjs.min.js'), loadStyle(this, VIS + '/copado-visjs/visjs.css')])
            .then(() => {
                this.handleLoad();
            })
            .catch(error => {
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });

        // subscribe to refreshDiagramClicked event
        registerListener('refreshDiagramClicked', this.handleLoad, this);
    }

    disconnectedCallback() {
        // unsubscribe from refreshDiagramClicked event
        unregisterAllListeners(this);
    }
}