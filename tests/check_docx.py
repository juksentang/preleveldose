"""Check native Word tables and literal text without Microsoft Word dependencies."""
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / 'tests'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}


def read(name):
    with ZipFile(ROOT / name) as archive:
        assert archive.testzip() is None
        document = ET.fromstring(archive.read('word/document.xml'))
    texts = [node.text or '' for node in document.findall('.//w:t', NS)]
    return document, '\n'.join(texts)


doc, text = read('diagnostics.docx')
tables = doc.findall('.//w:tbl', NS)
assert len(tables) == 6
assert all(len(t.findall('w:tr', NS)) == 6 for t in tables)
assert all(t.find('w:tr/w:trPr/w:tblHeader', NS) is not None for t in tables)
assert '0.0000' in text and '0.5000' in text
assert 'Bound relative to the coefficient (main reading)' in text
assert 'F. Instrumented side' in text
assert 'Secondary: anchor share kappa/beta' in text
assert 'all real' in text and 'empty' in text
assert 'Projection identity: passed' in text
assert 'Common controls mean the controls BEFORE' in text
assert (ROOT / 'diagnostics.docx').read_bytes() == (ROOT / 'protected_before.docx').read_bytes()
_, text = read('unicode.docx')
assert '诊断表 & 比较' in text
assert '重构基准 & 20% <not published>' in text
_, text = read('preserved_draft.docx')
assert 'Keep my unsaved document' in text
assert 'Diagnostic moments' not in text
_, text = read('legacy.docx')
assert 'not checked (legacy row)' in text
_, text = read('automatic.docx')
assert 'Reconstructed baseline OLS, not automatically a published estimate.' in text
print('PASS: native Word tables, numeric/text content, Unicode, legacy labels and file/draft protection')
