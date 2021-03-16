class Node {
    name;
    metadataType;
    isRootNode;
    isCategorySubNode;
    isLeafNode;

    constructor(name, metadataType) {
        this.name = name;
        this.metadataType = metadataType;
    }
}

export default class Graph {
    constructor() {
        this.vertices = [];
        this.edges = [];
    }

    addNode(nodeToInclude) {
        const isIncluded = this.vertices.some((node) => JSON.stringify(node) === JSON.stringify(nodeToInclude));
        if (!isIncluded) {
            this.vertices.push(nodeToInclude);
        }
    }

    addEdge(label, source, target) {
        const edgeToInclude = { label, source, target };
        const isIncluded = this.edges.some((edge) => JSON.stringify(edge) === JSON.stringify(edgeToInclude));
        if (!isIncluded) {
            this.edges.push(edgeToInclude);
        }
    }

    getRootNodes() {
        return this.vertices.filter((vertex) => vertex.isRootNode === true);
    }

    getRootEdges(nodeName) {
        return this.edges.filter((edge) => edge.source.name === nodeName && edge.target.isCategorySubNode === true);
    }

    getLeafEdges(nodeName) {
        return this.edges.filter((edge) => edge.source.name === nodeName && edge.target.isLeafNode === true);
    }

    getEdge(label, sourceName) {
        return this.edges.filter((edge) => edge.label === label && edge.source.name === sourceName);
    }

    importJson(jsonItem) {
        jsonItem.forEach((rootItem) => {
            const categoryTypeNode = new Node(rootItem.categoryType);
            categoryTypeNode.isRootNode = true;
            this.addNode(categoryTypeNode);

            rootItem.nodes.forEach((subNode) => {
                const categorySubNode = new Node(subNode.name, subNode.metadataType);
                categorySubNode.isCategorySubNode = true;
                this.addNode(categorySubNode);
                this.addEdge(subNode.name, categoryTypeNode, categorySubNode);

                subNode.fields.forEach((field) => {
                    const edgeName = field.split(':')[0];
                    const leafNodeName = field.split(':')[1].toLowerCase();

                    const leafNode = new Node(leafNodeName);
                    leafNode.isLeafNode = true;

                    this.addNode(leafNode);
                    this.addEdge(edgeName, categorySubNode, leafNode);
                });
            });
        });
        return this;
    }
}