// invoice.js — gemeinsame Rechnungs-PDF-Erzeugung für Kunde (zahlung.html) und Admin (admin-dashboard.html)
// Stellt window.HonigInvoice bereit. Erwartet, dass jsPDF (window.jspdf) geladen ist.
(function (global) {
  'use strict';

  // Normalisiert die Positionen einer Bestellung. Bestellungen ab dem Warenkorb
  // bringen ein items-Array mit; ältere haben Größe und Menge im Text ("375g × 2").
  function itemsOf(d) {
    if (Array.isArray(d.items) && d.items.length) {
      return d.items.map(function (i) {
        return {
          weight:    String(i.weight || ''),
          tracht:    String(i.tracht || 'frühtracht'),
          qty:       parseInt(i.qty, 10) || 1,
          unitPrice: Number(i.unitPrice) || 0
        };
      });
    }
    return [{
      weight:    String(d.groesse || ''),
      tracht:    String(d.tracht || 'frühtracht'),
      qty:       parseInt(d.qty, 10) || 1,
      unitPrice: Number(d.unitPrice) || 0
    }];
  }

  // Baut das Invoice-Daten-Objekt aus einem gespeicherten orders-Datensatz (Admin-Seite).
  function invoiceDataFromOrder(o) {
    const total = parseFloat(String(o.preis || '').replace(/[^0-9,.]/g, '').replace(',', '.')) || 0;

    let items;
    if (Array.isArray(o.items) && o.items.length) {
      items = itemsOf(o);
    } else {
      // Altbestellung: Menge steckt im Textfeld "groesse".
      const groesseRaw = String(o.groesse || '');
      let qty = 1;
      let baseSize = groesseRaw;
      if (groesseRaw.includes('×')) {
        const parts = groesseRaw.split('×');
        baseSize = parts[0].trim();
        qty = parseInt(parts[1], 10) || 1;
      }
      items = [{
        weight:    baseSize,
        tracht:    o.tracht || 'frühtracht',
        qty:       qty,
        unitPrice: qty > 0 ? total / qty : total
      }];
    }

    return {
      orderId:    '#' + String(o.id).padStart(4, '0'),
      datum:      o.datum || '',
      vorname:    o.vorname || '',
      nachname:   o.nachname || '',
      strasse:    o.strasse || '',
      hausnummer: o.hausnummer || '',
      plz:        o.plz || '',
      stadt:      o.stadt || '',
      items:      items,
      total:      total,
      isPaid:     false,
    };
  }

  // Erzeugt und speichert die Rechnungs-PDF. Identisch für Kunde und Admin.
  function generateInvoicePdf(d) {
    if (!d) return;
    const { jsPDF } = global.jspdf;
    const doc = new jsPDF({ unit: 'mm', format: 'a4' });

    const honey  = [184, 134, 42];
    const ink    = [26, 26, 26];
    const gray   = [120, 120, 120];
    const pageW  = 210;
    const margin = 20;
    const colR   = pageW - margin;

    // Header
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(22);
    doc.setTextColor(...honey);
    doc.text('RECHNUNG', margin, 28);

    doc.setFontSize(10);
    doc.setTextColor(...gray);
    doc.text('Honig aus Hochkamp', colR, 22, { align: 'right' });
    doc.setFont('helvetica', 'normal');
    doc.text('Julian Biegert', colR, 27, { align: 'right' });
    doc.text('Grotefendweg 15', colR, 32, { align: 'right' });
    doc.text('22589 Hamburg', colR, 37, { align: 'right' });
    doc.text('hochkamphonig@gmail.com', colR, 42, { align: 'right' });

    // Divider
    doc.setDrawColor(...honey);
    doc.setLineWidth(0.5);
    doc.line(margin, 48, colR, 48);

    // Order meta
    let y = 56;
    doc.setFontSize(9);
    doc.setTextColor(...gray);
    doc.text('Rechnungsnummer:', margin, y);
    doc.text('Datum:', margin + 70, y);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(...ink);
    doc.text(d.orderId || '—', margin + 38, y);
    doc.text(d.datum, margin + 86, y);

    // Customer
    y += 12;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(...gray);
    doc.text('Rechnungsempfänger:', margin, y);
    y += 6;
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(...ink);
    doc.setFontSize(10);
    doc.text(d.vorname + ' ' + d.nachname, margin, y);
    y += 5;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(...gray);
    doc.text(d.strasse + ' ' + d.hausnummer, margin, y);
    y += 5;
    doc.text(d.plz + ' ' + d.stadt, margin, y);

    // Table header
    y += 14;
    doc.setFillColor(245, 240, 235);
    doc.rect(margin, y - 5, colR - margin, 8, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(...ink);
    doc.text('Artikel', margin + 2, y);
    doc.text('Menge', 130, y);
    doc.text('Einzelpreis', 155, y);
    doc.text('Gesamt', colR - 2, y, { align: 'right' });

    // Table rows – eine Zeile je Position
    const items = itemsOf(d);
    y += 10;
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(...ink);
    items.forEach(function (item, idx) {
      if (idx > 0) y += 7;
      const trachtLabel = item.tracht.charAt(0).toUpperCase() + item.tracht.slice(1);
      doc.text('Honig aus Hochkamp – ' + item.weight + ' (' + trachtLabel + ')', margin + 2, y);
      doc.text(String(item.qty), 130, y);
      doc.text(item.unitPrice.toFixed(2).replace('.', ',') + ' €', 155, y);
      doc.text((item.qty * item.unitPrice).toFixed(2).replace('.', ',') + ' €', colR - 2, y, { align: 'right' });
    });

    // Total line
    y += 10;
    doc.setDrawColor(220, 220, 220);
    doc.setLineWidth(0.3);
    doc.line(margin, y - 4, colR, y - 4);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(11);
    doc.setTextColor(...honey);
    doc.text('Gesamtbetrag:', 140, y);
    doc.text(d.total.toFixed(2).replace('.', ',') + ' €', colR - 2, y, { align: 'right' });

    // Payment status
    y += 12;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(...gray);
    doc.text('Zahlungsstatus: Zahlung ausstehend – bitte ' + d.total.toFixed(2).replace('.', ',') + ' € per PayPal an @julianbgrt überweisen.', margin, y);

    // §19 note
    y += 10;
    doc.setTextColor(...gray);
    doc.text('Gemäß §19 UStG wird keine Umsatzsteuer berechnet.', margin, y);

    // Footer
    doc.setDrawColor(...honey);
    doc.setLineWidth(0.3);
    doc.line(margin, 280, colR, 280);
    doc.setFontSize(8);
    doc.setTextColor(...gray);
    doc.text('Honig aus Hochkamp – Julian Biegert – Grotefendweg 15 – 22589 Hamburg', pageW / 2, 285, { align: 'center' });

    doc.save('Rechnung-' + (d.orderId || 'Bestellung') + '.pdf');
  }

  global.HonigInvoice = { generateInvoicePdf, invoiceDataFromOrder };
})(window);
