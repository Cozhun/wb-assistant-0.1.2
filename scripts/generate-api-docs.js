const fs = require('fs');
const path = require('path');
const ts = require('typescript');
const glob = require('glob');

const SRC_DIR = path.join(__dirname, '..', 'src');
const DOCS_DIR = path.join(__dirname, '..', 'docs');
const API_DOCS = path.join(DOCS_DIR, 'wb-api.md');

function generateApiDocs() {
  const files = glob.sync('**/*.ts', { cwd: SRC_DIR });
  const interfaces = [];
  const functions = [];
  const classes = [];

  files.forEach(file => {
    const filePath = path.join(SRC_DIR, file);
    const sourceFile = ts.createSourceFile(
      file,
      fs.readFileSync(filePath, 'utf8'),
      ts.ScriptTarget.Latest,
      true
    );

    function visit(node) {
      if (ts.isInterfaceDeclaration(node)) {
        interfaces.push(extractInterface(node));
      } else if (ts.isFunctionDeclaration(node)) {
        functions.push(extractFunction(node));
      } else if (ts.isClassDeclaration(node)) {
        classes.push(extractClass(node));
      }
      ts.forEachChild(node, visit);
    }

    visit(sourceFile);
  });

  const docs = generateMarkdown(interfaces, functions, classes);
  fs.writeFileSync(API_DOCS, docs, 'utf8');
}

function extractInterface(node) {
  return {
    name: node.name.text,
    members: node.members.map(member => ({
      name: member.name.text,
      type: member.type.getText(),
      docs: ts.getJSDocComments(member)?.map(doc => doc.text).join('\n')
    }))
  };
}

function extractFunction(node) {
  return {
    name: node.name?.text,
    parameters: node.parameters.map(param => ({
      name: param.name.text,
      type: param.type.getText()
    })),
    returnType: node.type?.getText(),
    docs: ts.getJSDocComments(node)?.map(doc => doc.text).join('\n')
  };
}

function extractClass(node) {
  return {
    name: node.name?.text,
    methods: node.members
      .filter(member => ts.isMethodDeclaration(member))
      .map(method => ({
        name: method.name.text,
        parameters: method.parameters.map(param => ({
          name: param.name.text,
          type: param.type.getText()
        })),
        returnType: method.type?.getText(),
        docs: ts.getJSDocComments(method)?.map(doc => doc.text).join('\n')
      }))
  };
}

function generateMarkdown(interfaces, functions, classes) {
  let md = '# API Documentation\n\n';

  if (interfaces.length) {
    md += '## Interfaces\n\n';
    interfaces.forEach(iface => {
      md += `### ${iface.name}\n\n`;
      iface.members.forEach(member => {
        md += `- \`${member.name}\`: ${member.type}\n`;
        if (member.docs) md += `  ${member.docs}\n`;
      });
      md += '\n';
    });
  }

  if (functions.length) {
    md += '## Functions\n\n';
    functions.forEach(func => {
      md += `### ${func.name}\n\n`;
      if (func.docs) md += `${func.docs}\n\n`;
      md += '```typescript\n';
      md += `function ${func.name}(${func.parameters.map(p => 
        `${p.name}: ${p.type}`).join(', ')}): ${func.returnType}\n`;
      md += '```\n\n';
    });
  }

  if (classes.length) {
    md += '## Classes\n\n';
    classes.forEach(cls => {
      md += `### ${cls.name}\n\n`;
      cls.methods.forEach(method => {
        if (method.docs) md += `${method.docs}\n\n`;
        md += '```typescript\n';
        md += `${method.name}(${method.parameters.map(p => 
          `${p.name}: ${p.type}`).join(', ')}): ${method.returnType}\n`;
        md += '```\n\n';
      });
    });
  }

  return md;
}

generateApiDocs(); 