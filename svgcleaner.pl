#!/usr/bin/perl

# Copyright 2011, 2012 Andrey Bayrak.
# This script is a part of SVG Cleaner.
# SVG Cleaner is licensed under the GNU General Public License, Version 3.
# The GNU General Public License is a free, copyleft license for software and other kinds of works.
# http://www.gnu.org/copyleft/gpl.html

# ppa:svg-cleaner-team/svgcleaner-dev

# THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


# Опция "Recalculate coordinates and remove transform attributes when possible" иногда может приводить к искажению градиентов, причем непонятно почему (закономерности пока не выявлены).

use strict;
use warnings;

use XML::Twig;
use Term::ANSIColor;

# преобразуем строку аргументов оптимизации в хэш
my %args = map { split("=",$_) } split(":",$ARGV[1]);

# массив с именами всех элементов SVG
my @svg_elts = (
  'a','altGlyph','altGlyphDef','altGlyphItem',
  'animate','animateColor','animateMotion','animateTransform',
  'circle','clipPath','color-profile','cursor',
  'defs','desc','ellipse','feBlend',
  'feColorMatrix','feComponentTransfer','feComposite','feConvolveMatrix',
  'feDiffuseLighting','feDisplacementMap','feDistantLight','feFlood',
  'feFuncA','feFuncB','feFuncG','feFuncR',
  'feGaussianBlur','feImage','feMerge','feMergeNode',
  'feMorphology','feOffset','fePointLight','feSpecularLighting',
  'feSpotLight','feTile','feTurbulence','filter',
  'font','font-face','font-face-format','font-face-name',
  'font-face-src','font-face-uri','foreignObject','g',
  'glyph','glyphRef','hkern','image',
  'line','linearGradient','marker','mask',
  'metadata','missing-glyph','mpath','path',
  'pattern','polygon','polyline','radialGradient',
  'rect','script','set','stop',
  'style','svg','switch','symbol',
  'text','textPath','title','tref',
  'tspan','use','view','vkern');

# массив атрибутов Presentation attributes
my @present_atts = (
  'alignment-baseline','baseline-shift','clip-path','clip-rule','clip',
  'color-interpolation-filters','color-interpolation','color-profile',
  'color-rendering','color','cursor','direction','display','dominant-baseline',
  'enable-background','fill-opacity','fill-rule','fill','filter','flood-color',
  'flood-opacity','font-family','font-size-adjust','font-size','font-stretch',
  'font-style','font-variant','font-weight','glyph-orientation-horizontal',
  'glyph-orientation-vertical','image-rendering','kerning','letter-spacing',
  'lighting-color','marker-end','marker-mid','marker-start','mask','opacity',
  'overflow','pointer-events','shape-rendering','stop-color','stop-opacity',
  'stroke-dasharray','stroke-dashoffset','stroke-linecap','stroke-linejoin',
  'stroke-miterlimit','stroke-opacity','stroke-width','stroke','text-anchor',
  'text-decoration','text-rendering','unicode-bidi','visibility','word-spacing','writing-mode');

# массив элементов, использующих Presentation attributes
my @present_elts = (
  'a','altGlyph','animate','animateColor','circle','clipPath','defs','ellipse',
  'feBlend','feColorMatrix','feComponentTransfer','feComposite','feConvolveMatrix',
  'feDiffuseLighting','feDisplacementMap','feFlood','feGaussianBlur','feImage','feMerge',
  'feMorphology','feOffset','feSpecularLighting','feTile','feTurbulence','filter','font',
  'foreignObject','g','glyph','glyphRef','image','line','linearGradient','marker','mask',
  'missing-glyph','path','pattern','polygon','polyline','radialGradient','rect','stop',
  'svg','switch','symbol','text','textPath','tref','tspan','use');

# массив атрибутов Regular attributes
my @regular_atts = (
  'accent-height','accumulate','additive','alphabetic','amplitude','arabic-form','ascent',
  'attributeName','attributeType','azimuth','baseFrequency','baseProfile','bbox','begin','bias',
  'by','calcMode','cap-height','class','clipPathUnits','contentScriptType','contentStyleType','cx',
  'cy','d','descent','diffuseConstant','divisor','dur','dx','dy','edgeMode','elevation','end',
  'exponent','externalResourcesRequired','fill','filterRes','filterUnits','font-family','font-size',
  'font-stretch','font-style','font-variant','font-weight','format','from','fx','fy','g1','g2',
  'glyph-name','glyphRef','gradientTransform','gradientUnits','hanging','height','horiz-adv-x',
  'horiz-origin-x','horiz-origin-y','id','ideographic','in','in2','intercept','k','k1','k2','k3','k4',
  'kernelMatrix','kernelUnitLength','keyPoints','keySplines','keyTimes','lang','lengthAdjust',
  'limitingConeAngle','local', 'marker',  'markerHeight','markerUnits','markerWidth','maskContentUnits',
  'maskUnits','mathematical','max','media','method','min','mode','name','numOctaves','offset',
  'onabort','onactivate','onbegin','onclick','onend','onerror','onfocusin','onfocusout','onload',
  'onmousedown','onmousemove','onmouseout','onmouseover','onmouseup','onrepeat','onresize','onscroll',
  'onunload','onzoom','operator','order','orient','orientation','origin','overline-position',
  'overline-thickness','panose-1','path','pathLength','patternContentUnits','patternTransform',
  'patternUnits','points','pointsAtX','pointsAtY','pointsAtZ','preserveAlpha','preserveAspectRatio',
  'primitiveUnits','r','radius','refX','refY','rendering-intent','repeatCount','repeatDur',
  'requiredExtensions','requiredFeatures','restart','result','rotate','rx','ry','scale','seed','slope',
  'spacing','specularConstant','specularExponent','spreadMethod','startOffset','stdDeviation','stemh',
  'stemv','stitchTiles','strikethrough-position','strikethrough-thickness','string','style',
  'surfaceScale','systemLanguage','tableValues','target','targetX','targetY','textLength','title','to',
  'transform','type','u1','u2','underline-position','underline-thickness','unicode','unicode-range',
  'units-per-em','v-alphabetic','v-hanging','v-ideographic','v-mathematical','values','version',
  'vert-adv-y','vert-origin-x','vert-origin-y','viewBox','viewTarget','width','widths','x','x-height',
  'x1','x2','xChannelSelector','xlink:actuate','xlink:arcrole','xlink:href','xlink:role','xlink:show',
  'xlink:title','xlink:type','xml:base','xml:lang','xml:space', 'xmlns','y','y1','y2','yChannelSelector',
  'z', 'zoomAndPan');

# хэш соответствия атрибутов Presentation attributes конкретным типам элементов
my %pres_atts = (
  'alignment-baseline' => ['tspan', 'tref', 'altGlyph', 'textPath', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'baseline-shift' => ['tspan', 'tref', 'altGlyph', 'textPath', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'clip' => ['image', 'foreignObject', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'clip-path' => ['clipPath', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use'],
  'color' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set', 'path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'stop', 'feFlood', 'feDiffuseLighting', 'feSpecularLighting', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'color-interpolation' => ['a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use', 'animate', 'animateColor'],
  'color-interpolation-filters' => ['feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'color-profile' => ['image', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'color-rendering' => ['a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use', 'animate', 'animateColor'],
  'cursor' => ['a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use'],
  'direction' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'display' => ['svg', 'g', 'switch', 'a', 'foreignObject', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use', 'altGlyph', 'textPath', 'text', 'tref', 'tspan'],
  'dominant-baseline' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'enable-background' => ['a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol'],
  'fill' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set', 'path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'fill-opacity' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'fill-rule' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'filter' => ['a', 'defs', 'glyph', 'g', 'marker', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use'],
  'flood-color' => ['feFlood', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'flood-opacity' => ['feFlood', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan'],
  'font-family' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-size' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-size-adjust' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-stretch' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-style' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-variant' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'font-weight' => ['font-face', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'glyph-orientation-horizontal' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'glyph-orientation-vertical' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'image-rendering' => ['image', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'kerning' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'letter-spacing' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'lighting-color' => ['feDiffuseLighting', 'feSpecularLighting', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'marker' => ['path', 'line', 'polyline', 'polygon'],
  'marker-end' => ['path', 'line', 'polyline', 'polygon', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'marker-mid' => ['path', 'line', 'polyline', 'polygon', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'marker-start' => ['path', 'line', 'polyline', 'polygon', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'mask' => ['a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use'],
  'opacity' => ['a', 'defs', 'glyph', 'g', 'marker', 'missing-glyph', 'pattern', 'svg', 'switch', 'symbol', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use'],
  'overflow' => ['image', 'foreignObject', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'pointer-events' => ['circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'shape-rendering' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'stop-color' => ['stop'],
  'stop-opacity' => ['stop'],
  'stroke' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-dasharray' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-dashoffset' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-linecap' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-linejoin' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-miterlimit' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-opacity' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'stroke-width' => ['path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol','use'],
  'text-anchor' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'text-decoration' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'text-rendering' => ['text', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'unicode-bidi' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'visibility' => ['circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text', 'use', 'altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'word-spacing' => ['altGlyph', 'textPath', 'text', 'tref', 'tspan', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol'],
  'writing-mode' => ['text', 'a', 'defs', 'glyph', 'g', 'marker', 'mask', 'missing-glyph', 'pattern', 'svg', 'switch','symbol']);

# хэш соответствия атрибутов Regular attributes конкретным типам элементов
my %reg_atts = (
  'accent-height' => ['font-face'],
  'accumulate' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'additive' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'alphabetic' => ['font-face'],
  'amplitude' => ['feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'arabic-form' => ['glyph'],
  'ascent' => ['font-face'],
  'attributeName' => ['animate', 'animateColor', 'animateTransform', 'set'],
  'attributeType' => ['animate', 'animateColor', 'animateTransform', 'set'],
  'azimuth' => ['feDistantLight'],
  'baseFrequency' => ['feTurbulence'],
  'baseProfile' => ['svg'],
  'bbox' => ['font-face'],
  'begin' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'bias' => ['feConvolveMatrix'],
  'by' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'calcMode' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'cap-height' => ['font-face'],
  'class' => ['a', 'altGlyph', 'circle', 'clipPath', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'filter', 'font', 'foreignObject', 'g', 'glyph', 'glyphRef', 'image', 'line', 'linearGradient', 'marker', 'mask', 'missing-glyph', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'stop', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use'],
  'clipPathUnits' => ['clipPath'],
  'contentScriptType' => ['svg'],
  'contentStyleType' => ['svg'],
  'cx' => ['circle', 'ellipse', 'radialGradient'],
  'cy' => ['circle', 'ellipse', 'radialGradient'],
  'd' => ['path', 'glyph', 'missing-glyph'],
  'descent' => ['font-face'],
  'diffuseConstant' => ['feDiffuseLighting'],
  'divisor' => ['feConvolveMatrix'],
  'dur' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'dx' => ['altGlyph', 'feOffset', 'glyphRef', 'text', 'tref', 'tspan'],
  'dy' => ['altGlyph', 'feOffset', 'glyphRef', 'text', 'tref', 'tspan'],
  'edgeMode' => ['feConvolveMatrix'],
  'elevation' => ['feDistantLight'],
  'end' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'exponent' => ['feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'externalResourcesRequired' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'cursor', 'defs', 'ellipse', 'feImage', 'filter', 'font', 'foreignObject', 'g', 'image', 'line', 'linearGradient', 'marker', 'mask', 'mpath', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'script', 'set', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use', 'view'],
  'filterRes' => ['filter'],
  'filterUnits' => ['filter'],
  'format' => ['altGlyph', 'glyphRef'],
  'from' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'fx' => ['radialGradient'],
  'fy' => ['radialGradient'],
  'g1' => ['hkern', 'vkern'],
  'g2' => ['hkern', 'vkern'],
  'glyph-name' => ['glyph'],
  'glyphRef' => ['altGlyph', 'glyphRef'],
  'gradientTransform' => ['linearGradient', 'radialGradient'],
  'gradientUnits' => ['linearGradient', 'radialGradient'],
  'hanging' => ['font-face'],
  'height' => ['filter', 'foreignObject', 'image', 'pattern', 'rect', 'svg', 'use', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'mask'],
  'horiz-adv-x' => ['font', 'glyph', 'missing-glyph'],
  'horiz-origin-x' => ['font'],
  'horiz-origin-y' => ['font'],
  'id' => ['a', 'altGlyph', 'altGlyphDef', 'altGlyphItem', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'color-profile', 'cursor', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feDistantLight', 'feFlood', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR', 'feGaussianBlur', 'feImage', 'feMerge', 'feMergeNode', 'feMorphology', 'feOffset', 'fePointLight', 'feSpecularLighting', 'feSpotLight', 'feTile', 'feTurbulence', 'filter', 'font', 'font-face', 'font-face-format', 'font-face-name', 'font-face-src', 'font-face-uri', 'foreignObject', 'g', 'glyph', 'glyphRef', 'hkern', 'image', 'line', 'linearGradient', 'marker', 'mask', 'metadata', 'missing-glyph', 'mpath', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'script', 'set', 'stop', 'style', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use', 'view', 'vkern'],
  'ideographic' => ['font-face'],
  'in' => ['feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feGaussianBlur', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile'],
  'in2' => ['feBlend', 'feComposite', 'feDisplacementMap'],
  'intercept' => ['feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'k' => ['hkern', 'vkern'],
  'k1' => ['feComposite'],
  'k2' => ['feComposite'],
  'k3' => ['feComposite'],
  'k4' => ['feComposite'],
  'kernelMatrix' => ['feConvolveMatrix'],
  'kernelUnitLength' => ['feConvolveMatrix', 'feDiffuseLighting', 'feSpecularLighting'],
  'keyPoints' => ['animateMotion'],
  'keySplines' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'keyTimes' => ['animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'lang' => ['glyph'],
  'lengthAdjust' => ['text', 'textPath', 'tref', 'tspan'],
  'limitingConeAngle' => ['feSpotLight'],
  'local' => ['color-profile'],
  'marker' => ['path', 'line', 'polyline', 'polygon'],
  'markerHeight' => ['marker'],
  'markerUnits' => ['marker'],
  'markerWidth' => ['marker'],
  'maskContentUnits' => ['mask'],
  'maskUnits' => ['mask'],
  'mathematical' => ['font-face'],
  'max' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'media' => ['style'],
  'method' => ['textPath'],
  'min' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'mode' => ['feBlend'],
  'name' => ['color-profile', 'font-face-name'],
  'numOctaves' => ['feTurbulence'],
  'offset' => ['stop', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'onabort' => ['svg'],
  'onactivate' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onbegin' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'onclick' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onend' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'onerror' => ['svg'],
  'onfocusin' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onfocusout' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onload' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'onmousedown' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onmousemove' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onmouseout' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onmouseover' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onmouseup' => ['a', 'altGlyph', 'circle', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'svg', 'switch', 'symbol', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'onrepeat' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'onresize' => ['svg'],
  'onscroll' => ['svg'],
  'onunload' => ['svg'],
  'onzoom' => ['svg'],
  'operator' => ['feComposite', 'feMorphology'],
  'order' => ['feConvolveMatrix'],
  'orient' => ['marker'],
  'orientation' => ['glyph'],
  'origin' => ['animateMotion'],
  'overline-position' => ['font-face'],
  'overline-thickness' => ['font-face'],
  'panose-1' => ['font-face'],
  'path' => ['animateMotion'],
  'pathLength' => ['path'],
  'patternContentUnits' => ['pattern'],
  'patternTransform' => ['pattern'],
  'patternUnits' => ['pattern'],
  'points' => ['polygon', 'polyline'],
  'pointsAtX' => ['feSpotLight'],
  'pointsAtY' => ['feSpotLight'],
  'pointsAtZ' => ['feSpotLight'],
  'preserveAlpha' => ['feConvolveMatrix'],
  'preserveAspectRatio' => ['feImage', 'image', 'marker', 'pattern', 'svg', 'symbol', 'view'],
  'primitiveUnits' => ['filter'],
  'r' => ['circle', 'radialGradient'],
  'radius' => ['feMorphology'],
  'refX' => ['marker'],
  'refY' => ['marker'],
  'rendering-intent' => ['color-profile'],
  'repeatCount' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'repeatDur' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'requiredExtensions' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'cursor', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'mask', 'path', 'pattern', 'polygon', 'polyline', 'rect', 'set', 'svg', 'switch', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'requiredFeatures' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'cursor', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'mask', 'path', 'pattern', 'polygon', 'polyline', 'rect', 'set', 'svg', 'switch', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'restart' => ['animate', 'animateColor', 'animateMotion', 'animateTransform', 'set'],
  'result' => ['feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence'],
  'rotate' => ['altGlyph', 'animateMotion', 'text', 'tref', 'tspan'],
  'rx' => ['ellipse', 'rect'],
  'ry' => ['ellipse', 'rect'],
  'scale' => ['feDisplacementMap'],
  'seed' => ['feTurbulence'],
  'slope' => ['font-face', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'spacing' => ['textPath'],
  'specularConstant' => ['feSpecularLighting'],
  'specularExponent' => ['feSpecularLighting', 'feSpotLight'],
  'spreadMethod' => ['linearGradient', 'radialGradient'],
  'startOffset' => ['textPath'],
  'stdDeviation' => ['feGaussianBlur'],
  'stemh' => ['font-face'],
  'stemv' => ['font-face'],
  'stitchTiles' => ['feTurbulence'],
  'strikethrough-position' => ['font-face'],
  'strikethrough-thickness' => ['font-face'],
  'string' => ['font-face-format'],
  'style' => ['a', 'altGlyph', 'circle', 'clipPath', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'filter', 'font', 'foreignObject', 'g', 'glyph', 'glyphRef', 'image', 'line', 'linearGradient', 'marker', 'mask', 'missing-glyph', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'stop', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use'],
  'surfaceScale' => ['feDiffuseLighting', 'feSpecularLighting'],
  'systemLanguage' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'cursor', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'mask', 'path', 'pattern', 'polygon', 'polyline', 'rect', 'set', 'svg', 'switch', 'text', 'textPath', 'tref', 'tspan', 'use'],
  'tableValues' => ['feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'target' => ['a'],
  'targetX' => ['feConvolveMatrix'],
  'targetY' => ['feConvolveMatrix'],
  'textLength' => ['text', 'textPath', 'tref', 'tspan'],
  'title' => ['style'],
  'to' => ['set', 'animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'transform' => ['a', 'circle', 'clipPath', 'defs', 'ellipse', 'foreignObject', 'g', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'switch', 'text', 'use'],
  'type' => ['animateTransform', 'feColorMatrix', 'feTurbulence', 'script', 'style', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR'],
  'u1' => ['hkern', 'vkern'],
  'u2' => ['hkern', 'vkern'],
  'underline-position' => ['font-face'],
  'underline-thickness' => ['font-face'],
  'unicode' => ['glyph'],
  'unicode-range' => ['font-face'],
  'units-per-em' => ['font-face'],
  'v-alphabetic' => ['font-face'],
  'v-hanging' => ['font-face'],
  'v-ideographic' => ['font-face'],
  'v-mathematical' => ['font-face'],
  'values' => ['feColorMatrix', 'animate', 'animateColor', 'animateMotion', 'animateTransform'],
  'version' => ['svg'],
  'vert-adv-y' => ['font', 'glyph', 'missing-glyph'],
  'vert-origin-x' => ['font', 'glyph', 'missing-glyph'],
  'vert-origin-y' => ['font', 'glyph', 'missing-glyph'],
  'viewBox' => ['marker', 'pattern', 'svg', 'symbol', 'view'],
  'viewTarget' => ['view'],
  'width' => ['filter', 'foreignObject', 'image', 'pattern', 'rect', 'svg', 'use', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'mask'],
  'widths' => ['font-face'],
  'x' => ['altGlyph', 'cursor', 'fePointLight', 'feSpotLight', 'filter', 'foreignObject', 'glyphRef', 'image', 'pattern', 'rect', 'svg', 'text', 'use', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'mask', 'tref', 'tspan'],
  'x-height' => ['font-face'],
  'x1' => ['line', 'linearGradient'],
  'x2' => ['line', 'linearGradient'],
  'xChannelSelector' => ['feDisplacementMap'],
  'xlink:actuate' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'mpath', 'pattern', 'script', 'set', 'use'],
  'xlink:arcrole' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'linearGradient', 'mpath', 'pattern', 'radialGradient', 'script', 'set', 'textPath', 'tref', 'use'],
  'xlink:href' => ['a', 'altGlyph', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'linearGradient', 'mpath', 'pattern', 'radialGradient', 'script', 'textPath', 'use', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'set', 'tref'],
  'xlink:role' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'linearGradient', 'mpath', 'pattern', 'radialGradient', 'script', 'set', 'textPath', 'tref', 'use'],
  'xlink:show' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'mpath', 'pattern', 'script', 'set', 'use'],
  'xlink:title' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'linearGradient', 'mpath', 'pattern', 'radialGradient', 'script', 'set', 'textPath', 'tref', 'use'],
  'xlink:type' => ['a', 'altGlyph', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'color-profile', 'cursor', 'feImage', 'filter', 'font-face-uri', 'glyphRef', 'image', 'linearGradient', 'mpath', 'pattern', 'radialGradient', 'script', 'set', 'textPath', 'tref', 'use'],
  'xml:base' => ['a', 'altGlyph', 'altGlyphDef', 'altGlyphItem', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'color-profile', 'cursor', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feDistantLight', 'feFlood', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR', 'feGaussianBlur', 'feImage', 'feMerge', 'feMergeNode', 'feMorphology', 'feOffset', 'fePointLight', 'feSpecularLighting', 'feSpotLight', 'feTile', 'feTurbulence', 'filter', 'font', 'font-face', 'font-face-format', 'font-face-name', 'font-face-src', 'font-face-uri', 'foreignObject', 'g', 'glyph', 'glyphRef', 'hkern', 'image', 'line', 'linearGradient', 'marker', 'mask', 'metadata', 'missing-glyph', 'mpath', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'script', 'set', 'stop', 'style', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use', 'view', 'vkern'],
  'xml:lang' => ['a', 'altGlyph', 'altGlyphDef', 'altGlyphItem', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'color-profile', 'cursor', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feDistantLight', 'feFlood', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR', 'feGaussianBlur', 'feImage', 'feMerge', 'feMergeNode', 'feMorphology', 'feOffset', 'fePointLight', 'feSpecularLighting', 'feSpotLight', 'feTile', 'feTurbulence', 'filter', 'font', 'font-face', 'font-face-format', 'font-face-name', 'font-face-src', 'font-face-uri', 'foreignObject', 'g', 'glyph', 'glyphRef', 'hkern', 'image', 'line', 'linearGradient', 'marker', 'mask', 'metadata', 'missing-glyph', 'mpath', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'script', 'set', 'stop', 'style', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use', 'view', 'vkern'],
  'xml:space' => ['a', 'altGlyph', 'altGlyphDef', 'altGlyphItem', 'animate', 'animateColor', 'animateMotion', 'animateTransform', 'circle', 'clipPath', 'color-profile', 'cursor', 'defs', 'desc', 'ellipse', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feDistantLight', 'feFlood', 'feFuncA', 'feFuncB', 'feFuncG', 'feFuncR', 'feGaussianBlur', 'feImage', 'feMerge', 'feMergeNode', 'feMorphology', 'feOffset', 'fePointLight', 'feSpecularLighting', 'feSpotLight', 'feTile', 'feTurbulence', 'filter', 'font', 'font-face', 'font-face-format', 'font-face-name', 'font-face-src', 'font-face-uri', 'foreignObject', 'g', 'glyph', 'glyphRef', 'hkern', 'image', 'line', 'linearGradient', 'marker', 'mask', 'metadata', 'missing-glyph', 'mpath', 'path', 'pattern', 'polygon', 'polyline', 'radialGradient', 'rect', 'script', 'set', 'stop', 'style', 'svg', 'switch', 'symbol', 'text', 'textPath', 'title', 'tref', 'tspan', 'use', 'view', 'vkern'],
  'xmlns' => ['svg'],
  'y' => ['altGlyph', 'cursor', 'fePointLight', 'feSpotLight', 'filter', 'foreignObject', 'glyphRef', 'image', 'pattern', 'rect', 'svg', 'text', 'use', 'feBlend', 'feColorMatrix', 'feComponentTransfer', 'feComposite', 'feConvolveMatrix', 'feDiffuseLighting', 'feDisplacementMap', 'feFlood', 'feGaussianBlur', 'feImage', 'feMerge', 'feMorphology', 'feOffset', 'feSpecularLighting', 'feTile', 'feTurbulence', 'mask', 'tref', 'tspan'],
  'y1' => ['line', 'linearGradient'],
  'y2' => ['line', 'linearGradient'],
  'yChannelSelector' => ['feDisplacementMap'],
  'z' => ['fePointLight', 'feSpotLight'],
  'zoomAndPan' => ['svg', 'view']);

# массив атрибутов, имена и значения которых можно свести в атрибут style
my @style_atts = (
  'alignment-baseline', 'baseline-shift', 'clip', 'clip-path', 'clip-rule', 'color',
  'color-interpolation', 'color-interpolation-filters', 'color-profile', 'color-rendering',
  'cursor', 'direction', 'display', 'dominant-baseline', 'enable-background', 'fill',
  'fill-opacity', 'fill-rule', 'filter', 'flood-color', 'flood-opacity', 'font', 'font-family',
  'font-size', 'font-size-adjust', 'font-stretch', 'font-style', 'font-variant', 'font-weight',
  'glyph-orientation-horizontal', 'glyph-orientation-vertical', 'image-rendering', 'kerning',
  'letter-spacing', 'lighting-color', 'marker', 'marker-end', 'marker-mid', 'marker-start',
  'mask', 'opacity', 'overflow', 'pointer-events', 'shape-rendering', 'stop-color', 'stop-opacity',
  'stroke', 'stroke-dasharray', 'stroke-dashoffset', 'stroke-linecap', 'stroke-linejoin',
  'stroke-miterlimit', 'stroke-opacity', 'stroke-width', 'text-anchor', 'text-decoration',
  'text-rendering', 'unicode-bidi', 'visibility', 'word-spacing', 'writing-mode');

# массив элементов, которые должны находиться внутри элемента defs
my @defs_elts = (
  'altGlyphDef','clipPath','cursor','filter','linearGradient',
  'marker','mask','pattern','radialGradient','symbol');

# хэш дефолтных значений атрибутов
my %default_atts = (
  'baseline-shift' => 'baseline',
  'clip-path' => 'none',
  'clipPathUnits' => 'userSpaceOnUse',
  'clip-rule' => 'nonzero',
  'color' => '#000000',
  'color-interpolation-filters' => 'linearRGB',
  'color-interpolation' => 'sRGB',
  'direction' => 'ltr',
  'display' => 'inline',
  'enable-background' => 'accumulate',
  'fill' => '#000000',
  'fill-opacity' => '1',
  'fill-rule' => 'nonzero',
  'filter' => 'none',
  'flood-color' => '#000000',
  'flood-opacity' => '1',
  'font-size-adjust' => 'none',
  'font-size' => 'medium',
  'font-stretch' => 'normal',
  'font-style' => 'normal',
  'font-variant' => 'normal',
  'font-weight' => 'normal',
  'glyph-orientation-horizontal' => '0deg',
  'letter-spacing' => 'normal',
  'lighting-color' => '#ffffff',
  'marker' => 'none',
  'marker-start' => 'none',
  'marker-mid' => 'none',
  'marker-end' => 'none',
  'mask' => 'none',
  'opacity' => '1',
  'overflow' => 'visible',
  'pointer-events' => 'visiblePainted',
  'stop-color' => '#000000',
  'stop-opacity' => '1',
  'stroke' => 'none',
  'stroke-dasharray' => 'none',
  'stroke-dashoffset' => '0',
  'stroke-linecap' => 'butt',
  'stroke-linejoin' => 'miter',
  'stroke-miterlimit' => '4',
  'stroke-opacity' => '1',
  'stroke-width' => '1',
  'text-anchor' => 'start',
  'text-decoration' => 'none',
  'unicode-bidi' => 'normal',
  'visibility' => 'visible',
  'word-spacing' => 'normal',
  'writing-mode' => 'lr-tb',
  'audio-level' => '1',
  'solid-color' => '#000000',
  'solid-opacity' => '1',
  'text-align' => 'start',
  'vector-effect' => 'none',
  'viewport-fill' => 'none',
  'viewport-fill-opacity' => '1');

# массив пространств имен Adobe
my @adobe_ns = (
  'http://ns.adobe.com/AdobeIllustrator/10.0/',
  'http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/',
  'http://ns.adobe.com/Extensibility/1.0/',
  'http://ns.adobe.com/Flows/1.0/',
  'http://ns.adobe.com/Graphs/1.0/',
  'http://ns.adobe.com/GenericCustomNamespace/1.0/',
  'http://ns.adobe.com/ImageReplacement/1.0/',
  'http://ns.adobe.com/SaveForWeb/1.0/',
  'http://ns.adobe.com/Variables/1.0/',
  'http://ns.adobe.com/XPath/1.0/',
  'http://ns.adobe.com/xap/1.0/sType/ResourceRef#',
  'adobe:ns:meta/',
  'http://ns.adobe.com/xap/1.0/',
  'http://ns.adobe.com/xap/1.0/g/img/',
  'http://ns.adobe.com/xap/1.0/mm/');

# массив текстовых атрибутов
my @text_atts = (
  'alignment-baseline', 'baseline-shift', 'block-progression', 'direction',
  'dominant-baseline', 'dx', 'dy', 'font-family', 'font-size', 'font-size-adjust',
  'font-stretch', 'font-style', 'font-variant', 'font-weight', 'glyph-orientation-horizontal',
  'glyph-orientation-vertical', 'kerning', 'lengthAdjust', 'letter-spacing', 'line-height',
  'rotate', 'text-anchor', 'text-decoration', 'text-indent', 'textLength', 'text-rendering',
  'text-transform', 'unicode-bidi', 'word-spacing', 'writing-mode');

# хэш соответствия названий цветов их шестнадцатеричным кодам
my %colors = (
  'aliceblue' => '#f0f8ff',
  'antiquewhite' => '#faebd7',
  'aqua' => '#00ffff',
  'aquamarine' => '#7fffd4',
  'azure' => '#f0ffff',
  'beige' => '#f5f5dc',
  'bisque' => '#ffe4c4',
  'black' => '#000000',
  'blanchedalmond' => '#ffebcd',
  'blue' => '#0000ff',
  'blueviolet' => '#8a2be2',
  'brown' => '#a52a2a',
  'burlywood' => '#deb887',
  'cadetblue' => '#5f9ea0',
  'chartreuse' => '#7fff00',
  'chocolate' => '#d2691e',
  'coral' => '#ff7f50',
  'cornflowerblue' => '#6495ed',
  'cornsilk' => '#fff8dc',
  'crimson' => '#dc143c',
  'cyan' => '#00ffff',
  'darkblue' => '#00008b',
  'darkcyan' => '#008b8b',
  'darkgoldenrod' => '#b8860b',
  'darkgray' => '#a9a9a9',
  'darkgreen' => '#006400',
  'darkkhaki' => '#bdb76b',
  'darkmagenta' => '#8b008b',
  'darkolivegreen' => '#556b2f',
  'darkorange' => '#ff8c00',
  'darkorchid' => '#9932cc',
  'darkred' => '#8b0000',
  'darksalmon' => '#e9967a',
  'darkseagreen' => '#8fbc8f',
  'darkslateblue' => '#483d8b',
  'darkslategray' => '#2f4f4f',
  'darkturquoise' => '#00ced1',
  'darkviolet' => '#9400d3',
  'deeppink' => '#ff1493',
  'deepskyblue' => '#00bfff',
  'dimgray' => '#696969',
  'dodgerblue' => '#1e90ff',
  'firebrick' => '#b22222',
  'floralwhite' => '#fffaf0',
  'forestgreen' => '#228b22',
  'fuchsia' => '#ff00ff',
  'gainsboro' => '#dcdcdc',
  'ghostwhite' => '#f8f8ff',
  'gold' => '#ffd700',
  'goldenrod' => '#daa520',
  'gray' => '#808080',
  'green' => '#008000',
  'greenyellow' => '#adff2f',
  'honeydew' => '#f0fff0',
  'hotpink' => '#ff69b4',
  'indianred' => '#cd5c5c',
  'indigo' => '#4b0082',
  'ivory' => '#fffff0',
  'khaki' => '#f0e68c',
  'lavender' => '#e6e6fa',
  'lavenderblush' => '#fff0f5',
  'lawngreen' => '#7cfc00',
  'lemonchiffon' => '#fffacd',
  'lightblue' => '#add8e6',
  'lightcoral' => '#f08080',
  'lightcyan' => '#e0ffff',
  'lightgoldenrodyellow' => '#fafad2',
  'lightgreen' => '#90ee90',
  'lightgrey' => '#d3d3d3',
  'lightpink' => '#ffb6c1',
  'lightsalmon' => '#ffa07a',
  'lightseagreen' => '#20b2aa',
  'lightskyblue' => '#87cefa',
  'lightslategray' => '#778899',
  'lightsteelblue' => '#b0c4de',
  'lightyellow' => '#ffffe0',
  'lime' => '#00ff00',
  'limegreen' => '#32cd32',
  'linen' => '#faf0e6',
  'magenta' => '#ff00ff',
  'maroon' => '#800000',
  'mediumaquamarine' => '#66cdaa',
  'mediumblue' => '#0000cd',
  'mediumorchid' => '#ba55d3',
  'mediumpurple' => '#9370db',
  'mediumseagreen' => '#3cb371',
  'mediumslateblue' => '#7b68ee',
  'mediumspringgreen' => '#00fa9a',
  'mediumturquoise' => '#48d1cc',
  'mediumvioletred' => '#c71585',
  'midnightblue' => '#191970',
  'mintcream' => '#f5fffa',
  'mistyrose' => '#ffe4e1',
  'moccasin' => '#ffe4b5',
  'navajowhite' => '#ffdead',
  'navy' => '#000080',
  'oldlace' => '#fdf5e6',
  'olive' => '#808000',
  'olivedrab' => '#6b8e23',
  'orange' => '#ffa500',
  'orangered' => '#ff4500',
  'orchid' => '#da70d6',
  'palegoldenrod' => '#eee8aa',
  'palegreen' => '#98fb98',
  'paleturquoise' => '#afeeee',
  'palevioletred' => '#db7093',
  'papayawhip' => '#ffefd5',
  'peachpuff' => '#ffdab9',
  'peru' => '#cd853f',
  'pink' => '#ffc0cb',
  'plum' => '#dda0dd',
  'powderblue' => '#b0e0e6',
  'purple' => '#800080',
  'red' => '#ff0000',
  'rosybrown' => '#bc8f8f',
  'royalblue' => '#4169e1',
  'saddlebrown' => '#8b4513',
  'salmon' => '#fa8072',
  'sandybrown' => '#f4a460',
  'seagreen' => '#2e8b57',
  'seashell' => '#fff5ee',
  'sienna' => '#a0522d',
  'silver' => '#c0c0c0',
  'skyblue' => '#87ceeb',
  'slateblue' => '#6a5acd',
  'slategray' => '#708090',
  'snow' => '#fffafa',
  'springgreen' => '#00ff7f',
  'steelblue' => '#4682b4',
  'tan' => '#d2b48c',
  'teal' => '#008080',
  'thistle' => '#d8bfd8',
  'tomato' => '#ff6347',
  'turquoise' => '#40e0d0',
  'violet' => '#ee82ee',
  'wheat' => '#f5deb3',
  'white' => '#ffffff',
  'whitesmoke' => '#f5f5f5',
  'yellow' => '#ffff00',
  'yellowgreen' => '#9acd32');

# массив атрибутов, использующихся элементом clipPath
my @clip_atts = (
  'clip-rule', 'cx', 'cy', 'd', 'fill-rule', 'height', 'id',
  'points', 'r', 'rx', 'ry', 'transform', 'width', 'x', 'x1',
  'x2', 'y', 'y1', 'y2', 'xlink:href');

# массив элементов у которых нельзя удалять атрибуты fill с дефолтным значением, усли они находятся в секции defs
my @keep_fill = ('g','path','rect','circle','ellipse','line','polyline','polygon');

# массив атрибутов, использующихся элементом linearGradient
my @lingrad_atts = ('gradientUnits','spreadMethod','gradientTransform','x1','y1','x2','y2');

# массив атрибутов, использующихся элементом radialGradient
my @radgrad_atts = ('gradientUnits','spreadMethod','gradientTransform','fx','fy','cx','cy','r');


####################
# СЛУЖЕБНЫЕ ДАННЫЕ #
####################

# ширина и высота холста
my $actual_width;
my $actual_height;

# хэш описания элементов секции defs
my %desc_elts;

# хэш со ссылками идентичных элементов на первый по счету из них
my %comp_elts;

# массив, содержащий id удаленных элементов
my @del_elts;

# количество удаленных неиспользуемых id
my $id_removed;

# массив, содержащий префиксы пространств имен Adobe Illustrator
my @adobe_pref = ();

# id последнего удаленного элемента
my $del_id;

# массив, содержащий список id на которые имеются ссылки
my @ref_id = ();

# ссылка на другой элемент
my $link;

# хэш с id (ключ) и списками удаленных атрибутов градиентов (значение)
my %rem_gratts;

# хэш для определения количества ссылок одних градиентов на другие
my %xlinks;

# индекс, искользующийся для вывода результатов обработки атрибутов
my $i;

# шаблон числа с плавающей запятой
my $fpnum = qr/[-+]?\d*\.?\d+/;

# шаблон числа в экспоненциальном формате 
my $scinum = qr/[-+]?\d*\.?\d+[eE][-+]?\d+/;

# шаблон всех чисел (обычных и в экспоненциальном формате)
# my $num = qr/$scinum|$fpnum/;
my $exp = qr/[eE][+-]?\d+/;
my $fract_const = qr/\d*\.\d+|\d+\./;
my $fp_const = qr/$fract_const$exp?|\d+$exp/;
my $num = qr/[+-]?$fp_const|[+-]?\d+/;
my $flag = qr/0|1/;

# шаблон едениц измерения
my $unit = qr/px|pt|pc|mm|cm|m|in|ft|em|ex|%/;

# шаблон разделителя comma-wsp
my $cwsp = qr/\s+,?\s*|,\s*/;

# шаблон трансформации translate
my $translate = qr/translate\s*\(\s*($num)$cwsp?($num)?\s*\)/;

# шаблон трансформации scale
my $scale = qr/scale\s*\(\s*($num)$cwsp?($num)?\s*\)/;

# шаблон трансформации skewX
my $skewX = qr/skewX\s*\(\s*($num)\s*\)/;

# шаблон трансформации skewY
my $skewY = qr/skewY\s*\(\s*($num)\s*\)/;

# шаблон трансформации rotate_a
my $rotate_a = qr/rotate\s*\(\s*($num)\s*\)/;

# шаблон трансформации rotate_axy
my $rotate_axy = qr/rotate\s*\(\s*($num)$cwsp($num)$cwsp($num)\s*\)/;

# шаблон трансформации rotate
my $rotate = qr/rotate\s*\(\s*($num)$cwsp?($num)?$cwsp?($num)?\s*\)/;

# шаблон трансформации matrix
my $matrix = qr/matrix\s*\(\s*($num)$cwsp($num)$cwsp($num)$cwsp($num)$cwsp($num)$cwsp($num)\s*\)/;


################
# ПОДПРОГРАММЫ #
################

# подпрограмма удаления элемента
sub del_elt {

  $_[0]->delete;
  $del_id = $_[2];
  push @del_elts, $del_id;
  if ($ARGV[2] && $ARGV[2] ne "quiet") {
    print colored (" <$_[1]", 'bold red');
    print " id=\"$_[2]\" ($_[3])\n\n";
  }
}


# подпрограмма вывода результатов преобразования basic shape => path
sub bs_path {

  print colored (" <$_[0]", 'bold red');
  print " id=\"$_[1]\":\n";

  print colored ("  <path", 'bold green');
  print " id=\"$_[1]\" (it's the equivalent path element)\n\n";
}


# подпрограмма создающая строку с описанием элемента (имена элементов, атрибуты и их значения)
sub desc_elt {
  my $desc_elt="";
  foreach my $elt ($_[0]->descendants_or_self) {
    $desc_elt = $desc_elt.$elt->name;
    foreach my $att ($elt->att_names) {
      if ($att ne "id") {
	$desc_elt = $desc_elt.$att;
	$desc_elt = $desc_elt.$elt->att($att);
      }
    }
  }
  return $desc_elt;
}


# подпрограмма удаления атрибута
sub del_att {
  $i++;
  $_[0]->del_att("$_[1]");
  if ($ARGV[2] && $ARGV[2] ne "quiet") {
    if ($_[3] == 1) { print colored (" <$_[4]", 'bold');print " id=\"$_[5]\":" };
    print colored ("\n  •$_[1]", 'red'); print " ($_[2])";
  }
}


# подпрограмма создания атрибута
sub crt_att {
  $i++;
  if ($ARGV[2] && $ARGV[2] ne "quiet") {

  if ($_[3] == 1) { print colored (" <$_[4]", 'bold');print " id=\"$_[5]\":" };
  print colored ("\n  •$_[1]", 'green'); print " ($_[2])";
  }
}


# подпрограмма конвертации всех цветовых форматов в #RRGGBB
sub color_rrggbb {
  my $att_val = $_[0];
  # изменяем формат цвета с rgb(десятичные числа или проценты) на #RRGGBB
  if ($att_val=~ /^\s*rgb\(\s*(\d+)%?\s*,\s*(\d+)%?\s*,\s*(\d+)%?\s*\)\s*$/) {
    (my $r,my $g,my $b) = ($1,$2,$3);
    ($r,$g,$b) = ($r*255/100,$g*255/100,$b*255/100) if ($att_val=~ /%/);
    ($r,$g,$b) = split(' ',sprintf("%02x %02x %02x",int $r,int $g,int $b));
    $att_val = "#$r$g$b";
  }
  # изменяем формат цвета со слов на #RRGGBB
  if (exists($colors{"\L$att_val"})) {
    $att_val = $colors{"\L$att_val"};
  }
  # изменяем значение атрибута с верхнего регистра на нижний
  if ($att_val=~ /^#([\dA-F]){3}$|^#([\dA-F]){6}$/) {
    $att_val = "\L$att_val";
  }
  # преобразование формата #RRGGBB в #RGB, если это возможно
  if ($_[1] eq "yes" &&
      $att_val=~ /^#([\da-f])([\da-f])([\da-f])([\da-f])([\da-f])([\da-f])$/ &&
      ($1 eq $2 && $3 eq $4 && $5 eq $6)) {
    $att_val = "#$1$3$5";
  }

  return $att_val;
}


# подпрограмма округления десятичного числа
sub round_num {
  my $att_val = $_[0];
  my $unit = $_[1];
  my $dp = $_[2];
  # +0 нужен для удаления лишних правых крайних нулей
  $att_val = sprintf("%.${dp}f", $att_val)+0 if ($att_val=~ /([\d]*\.[\d][\d]{$dp,})/);
  $att_val=~ s/^0\./\./ if ($att_val=~ /^0\.[\d]+/);
  $att_val=~ s/^-0\./-\./ if ($att_val=~ /^-0\.[\d]+/);
  $att_val = $att_val.$unit if ($unit);

  return $att_val;
}


# подпрограмма пересчета всех возможных едениц измерения в пиксели
sub units_px {
  my $elt = $_[0];
  my $att = $_[1];
  my $att_val = $_[2];
  my $unit = $_[3];
  # пересчитываем em и ex в пиксели
  if ($unit~~['em','ex']) {
    # определяем размер фонта
    my $font_size = $elt->parent('*[@font-size=~ /\d$/]')->att('font-size');
    $font_size = $elt->att('font-size') unless ($font_size);
    $att_val = $att_val*$font_size if ($font_size && $unit eq "em");
    # исходим из того, что 1em = 2ex - грубое решение, но что поделаешь...
    $att_val = $att_val*$font_size/2 if ($font_size && $unit eq "ex");
    $att_val = 0 unless ($font_size);
  }
  # пересчитываем проценты
  if ($unit eq "%") {
    if ($att eq "offset") {
      $att_val = $att_val/100;
      $att_val = 0 if ($att_val < 0);
      $att_val = 1 if ($att_val > 1);
    }
    elsif ($att=~ /[Ww]idth$|^x$|^[cdfr]x$|^x[12]$|^refX$/) {
      $att_val = $att_val*$actual_width/100;
    }
    elsif ($att=~ /[Hh]eight$|^y$|^[cdfr]y$|^y[12]$|^refY$/) {
      $att_val = $att_val*$actual_height/100;
    }
    else {
      $att_val = sqrt($actual_width**2+$actual_height**2)*$att_val/(sqrt(2)*100);
    }
  }
  # пересчитываем остальные еденицы измерения в пиксели
  $att_val = $att_val if ($unit eq "px");
  $att_val = $att_val*1.25 if ($unit eq "pt");
  $att_val = $att_val*15 if ($unit eq "pc");
  $att_val = $att_val*3.543307 if ($unit eq "mm");
  $att_val = $att_val*35.43307 if ($unit eq "cm");
  $att_val = $att_val*3543.307 if ($unit eq "m");
  $att_val = $att_val*90 if ($unit eq "in");
  $att_val = $att_val*1080 if ($unit eq "ft");
  
  return $att_val;
}


# подпрограмма умножения матриц трансформации
sub nested_transform {
  my $a1;my $b1;my $c1;my $d1;my $e1;my $f1;
  if ($_[0]=~/^$matrix$/) {
    ($a1,$b1,$c1,$d1,$e1,$f1) = ($1,$2,$3,$4,$5,$6);
  }
  my $a2;my $b2;my $c2;my $d2;my $e2;my $f2;
  if ($_[1]=~/^$matrix$/) {
    ($a2,$b2,$c2,$d2,$e2,$f2) = ($1,$2,$3,$4,$5,$6);
  }
  my $a = $a1*$a2+$c1*$b2;
  my $b = $b1*$a2+$d1*$b2;
  my $c = $a1*$c2+$c1*$d2;
  my $d = $b1*$c2+$d1*$d2;
  my $e = $a1*$e2+$c1*$f2+$e1;
  my $f = $b1*$e2+$d1*$f2+$f1;

  return "matrix($a,$b,$c,$d,$e,$f)";
}


# подпрограмма исправления значения угла (приведение в диапазон 0...360)
sub opt_angle {
  my $angle = shift;
  if ($angle < 0) {
    $angle += 360 while ($angle < 0);
  } elsif ($angle > 360) {
    $angle -= 360 while ($angle > 360);
  }
  return $angle;
}


# подпрограмма вычисляющая тангенс угла (угол в градусах)
sub angle_tg {
  my $deg = shift;
  my $rad = ($deg/180)*3.14159265358979;

  unless ($deg~~['90','270']) {
    return sprintf("%.8f", sin($rad)/cos($rad))+0;
  } else {
    return "N/A";
  }
}


# подпрограмма вычисляющая косинус угла (угол в градусах)
sub angle_cos {
  my $deg = shift;
  my $rad = ($deg/180)*3.14159265358979;

  return sprintf("%.8f", cos($rad))+0;
}


# подпрограмма вычисляющая синус угла (угол в градусах)
sub angle_sin {
  my $deg = shift;
  my $rad = ($deg/180)*3.14159265358979;

  return sprintf("%.8f", sin($rad))+0;
}


# подпрограмма вычисляющая арксинус (угол в градусах)
sub asin { atan2($_[0],sqrt(1-$_[0]**2))*180/3.14159265358979 }

# подпрограмма вычисляющая арккосинус (угол в градусах)
sub acos { atan2(sqrt(1-$_[0]**2),$_[0])*180/3.14159265358979 }

# подпрограмма вычисляющая арктангенс (угол в градусах)
sub atan { atan2($_[0],1)*180/3.14159265358979 };


# подпрограмма преобразования всех видов трансформации (в т.ч. и нескольких подряд) в матрицу
sub trans_matrix {

  my $transform = shift;
  my @matrix;

  CYCLE_TRANS:
  while ($transform) {

    if ($transform=~ /^$cwsp/) {
      $transform=~ s/^$cwsp//;
      next CYCLE_TRANS;
    }

    # rotate(angle cx cy) => translate(cx,cy) rotate(angle) translate(-cx,-cy).
    if ($transform=~ /^$rotate_axy/) {
      my $angle = $1;
      my $cx = $2;
      my $cy = $3;
      my $cx_neg = $cx*(-1);
      my $cy_neg = $cy*(-1);
      $angle = &opt_angle($angle) if ($angle < 0 || $angle > 360);
      $angle = 0 if ($angle == 360);

      $transform=~ s/^$rotate_axy//;
      $transform = "translate($cx,$cy) rotate($angle) translate($cx_neg,$cy_neg) ".$transform;
      next CYCLE_TRANS;
    }

    # translate(tx [ty]) => matrix(1,0,0,1,tx,ty)
    if ($transform=~ /^$translate/) {
      my $tx = $1;
      my $ty = $2; $ty = 0 unless ($ty);

      $transform=~ s/^$translate//;
      push @matrix, "matrix(1,0,0,1,$tx,$ty)";
      next CYCLE_TRANS;
    }

    # scale(sx [sy]) => matrix(sx,0,0,sy,0,0)
    if ($transform=~ /^$scale/) {
      my $sx = $1;
      my $sy = $2; $sy = $sx unless ($sy);

      $transform=~ s/^$scale//;
      push @matrix, "matrix($sx,0,0,$sy,0,0)";
      next CYCLE_TRANS;
    }

    # skewX(angle) => matrix(1,0,tg(angle),1,0,0)
    if ($transform=~ /^$skewX/) {
      my $angle = $1;
      $angle = &opt_angle($angle) if ($angle < 0 || $angle > 360);
      $angle = 0 if ($angle == 360);
      my $tg = &angle_tg($angle);

      $transform=~ s/^$skewX//;
      push @matrix, "matrix(1,0,$tg,1,0,0)" unless ($tg eq "N/A");
      next CYCLE_TRANS;
    }

    # skewY(angle) => matrix(1,tg(angle),0,1,0,0)
    if ($transform=~ /^$skewY/) {
      my $angle = $1;
      $angle = &opt_angle($angle) if ($angle < 0 || $angle > 360);
      $angle = 0 if ($angle == 360);
      my $tg = &angle_tg($angle);

      $transform=~ s/^$skewY//;
      push @matrix, "matrix(1,$tg,0,1,0,0)" unless ($tg eq "N/A");
      next CYCLE_TRANS;
    }

    # rotate(angle) => matrix(cos(a),sin(a),-sin(a),cos(a),0,0)
    if ($transform=~ /^$rotate_a/) {
      my $angle = $1;
      $angle = &opt_angle($angle) if ($angle < 0 || $angle > 360);
      $angle = 0 if ($angle == 360);
      my $cos = &angle_cos($angle);
      my $sin = &angle_sin($angle);
      my $sin_neg = $sin*(-1);

      $transform=~ s/^$rotate_a//;
      push @matrix, "matrix($cos,$sin,$sin_neg,$cos,0,0)";
      next CYCLE_TRANS;
    }

    # matrix(a b c d e f)
    if ($transform=~ /^($matrix)/) {
      push @matrix, $1;
      $transform=~ s/^($matrix)//;
      next CYCLE_TRANS;
    }
  }

  if (scalar @matrix == 1) {
    $transform = shift @matrix;
  } else {
    $transform = shift @matrix;
    while ($matrix[0]) {
      my $cur_matrix = shift @matrix;
      $transform = &nested_transform($transform,$cur_matrix);
    }
  }
  return $transform;
}


#################
# ПАРСИНГ ФАЙЛА #
#################

# создаем объект XML::Twig
my $twig = XML::Twig->new(
  no_prolog => "$args{'no_prolog'}",
  comments => "$args{'comments'}",
  output_encoding => 'utf8',
  discard_spaces => 1);


# парсим файл
$twig->parsefile("$ARGV[0]");


# выводим имя файла
(my $file_name = $ARGV[0])=~ s/^.+\///;
(my $length = length ($file_name))+=2;
my $line = ('─' x $length);

if ($ARGV[2] && $ARGV[2] ne "quiet") {
  print "\n\n\n╓$line╖";
  print "\n║ "; print colored ("$file_name", 'bold'); print " ║";
  print "\n╙$line╜\n\n";
} else {
  print "\n$file_name\n\n";
}


# берем корневой элемент
my $root = $twig->root;



#############################
# ПРЕДВАРИТЕЛЬНАЯ ОБРАБОТКА #
#############################

print colored ("\nPREPROCESSING\n\n", 'bold blue underline') if ($ARGV[2] && $ARGV[2] ne "quiet");


# определяем начальный размер файла
my $size_initial = length($twig->sprint);


# определяем начальное количество элементов в файле
my $elts_initial = scalar($root->descendants_or_self);


# определяем начальное количество атрибутов в файле, а также преобразуем параметры атрибута style в атрибуты XML (это необходимо для последующих операций по оптимизации, которые используют XPath (XML Path Language) — язык запросов к элементам XML-документа)
my $atts_initial = 0;
foreach my $elt ($root->descendants_or_self) {

  $atts_initial+=($elt->att_nb);

  # удаляем префикс 'svg:' из имен элементов
  $elt->set_tag($1) if ($elt->name=~ /^svg:(.+)$/);

  # если элемент содержит атрибут style
  if (defined $elt->att('style')) {
    # создаем хэш, содержащий параметры и их значения
    my %style = map { split(":",$_) } split(";",$elt->att('style'));
    # удаляем атрибут style
    $elt->del_att('style');

    # создаем атрибуты XML
    while ((my $att, my $att_val) = each %style) {
      # если ключ хэша начинается с буквы (если ключ будет начинатся с иного символа то SVG-файл станет непригодным), то создаем атрибут с именем ключа хэша и параметром равным значению ключа хэша
      $att = $1 if ($att=~ /^\s+(.+)\s*$/);
      $att_val = $1 if ($att_val=~ /^\s+(.+)\s*$/);

      if ($att=~ /^fill$|^stroke$/ &&
	  $att_val=~ /^(url\(#[^\)]+\)).+$/) {

	$att_val = $1;
      }

	$elt->set_att($att => $att_val) if ($att=~ /^[a-z]/);
    }
  }

  # исправление значений атрибутов
  while ((my $att, my $att_val) = each %{$elt->atts}) {

    my $i;
    # удаляем крайние пробелы из значений атрибутов
    if ($att_val=~ /^(\s+)/) {
      $att_val = substr $att_val, length $1;
      $i = 1;
    }
    if ($att_val=~ /(\s+)$/) {
      $att_val = substr $att_val, 0, -(length $1);
      $i = 1;
    }

    # исправляем ошибки в атрибутах, параметры которых задают ссылки
    # параметр 'url(#<IRI>) любые символы' меняем на 'url(#<IRI>)'
    if ($att_val=~ /^url\(#[^\)]+\)(.+)$/) {
      $att_val = substr $att_val, 0, -(length $1);
      $i = 1;
    }

    # удаляем обозначение юнита 'px' - это дефолтная еденица измерения
    if ($att_val=~ /^($num)px$/) {
      $att_val = $1;
      $i = 1;
    }

    # исправляем нулевые параметры атрибутов
    if ($att_val=~ /^($num)($unit)?$/ && $1 == 0) {
      $att_val = 0;
      $i = 1;
    }

    # удаляем крайние правые нули в числах
    if ($att_val=~ /^([-+]?\d*\.\d*0+)($unit)?$/) {
      $att_val = $1+0;
      $att_val = $att_val.$2 if ($2);
      $i = 1;
    }

    # исправляем отрицательные параметры атрибутов ширины и высоты
    if ($att=~ /height$|width$|^r$|^rx$|^ry$/ && $att_val=~ /^-/) {
      $att_val = 0;
      $i = 1;
    }

    # исправляем значения прозрачности
    if ($att=~ /opacity$/ && $att_val < 0) {
      $att_val = 0;
      $i = 1;
    }
    elsif ($att=~ /opacity$/ && $att_val > 1) {
      $att_val = 1;
      $i = 1;
    }

    $elt->set_att($att => $att_val) if ($i);
  }
}


if ($ARGV[2] && $ARGV[2] ne "quiet") {
  # вывод начального размера файла
  print colored (" The initial file size is $size_initial bytes\n", 'bold');
  # вывод начального количества элементов
  print colored (" The initial number of elements is $elts_initial\n", 'bold');
  # вывод начального количества элементов
  print colored (" The initial number of attributes is $atts_initial\n\n", 'bold');
} else {
  print " The initial file size is $size_initial bytes\n";
  print " The initial number of elements is $elts_initial\n";
  print " The initial number of attributes is $atts_initial\n\n";
}


# определяем ширину и высоту холста
if ($root->att('width') && $root->att('height')) {

  $actual_width = $root->att('width');
  $actual_height = $root->att('height');

  # пересчитываем $actual_width и $actual_height, если их значения имеют еденицы измерения
  if ($actual_width=~ /^($num)($unit)$/ && $2 ne "%") {

    $actual_width = &units_px($root,$actual_width,$1,$2);
  }

  if ($root->att('viewBox') &&
      $actual_width=~ /%/ &&
      $root->att('viewBox')=~ /($num)\s*,?\s*($num)$/) {

    $actual_width = substr($actual_width,0,-1)*$1/100;
  }

  if ($actual_height=~ /^($num)($unit)$/ && $2 ne "%") {

    $actual_height = &units_px($root,"$actual_height",$1,$2);
  }

  if ($root->att('viewBox') &&
      $actual_height=~ /%/ &&
      $root->att('viewBox')=~ /($num)\s*,?\s*($num)$/) {

    $actual_height = substr($actual_height,0,-1)*$2/100;
  }

} elsif (!$root->att('width') && !$root->att('height') &&
	 $root->att('viewBox')=~ /($num)$cwsp($num)$/) {
# 	 $root->att('viewBox')=~ /($num)\s*,?\s*($num)$/) {

  $actual_width = $1;
  $actual_height = $2;
}


# принудительно увеличиваем точность округления дробных чисел для очень маленьких изображений (во избежание их искажения)
if (($actual_width < 64 || $actual_height < 64) &&
    $args{'round_numbers'} eq "yes") {

  $args{'dp_d'} = 5 if ($args{'dp_d'} < 5);
  $args{'dp_tr'} = 6 if ($args{'dp_tr'} < 6);
}


# определяем префиксы пространств имен Adobe Illustrator
if ($args{'adobe_elts'} eq "delete" ||
    $args{'adobe_atts'} eq "delete") {

  while ((my $att, my $att_val) = each %{$root->atts}) {

    if ($att_val~~@adobe_ns) {
      $att=~ s/^xmlns://;
      push @adobe_pref, $att;
    }
  }
}


# выбираем первый по счету элемент defs
my $defs = $twig->first_elt('defs');


# цикл: обрабатываем по порядку все элементы файла
CYCLE_DEF:
foreach ($root->descendants) {
  # получаем имя элемента
  my $elt_name = $_->name;
  # получаем id элемента
  my $elt_id = $_->id;
  $elt_id = "none" unless ($elt_id);

  # если элемент должен находиться внутри элемента defs, но находится вне его
  if ($elt_name ~~ @defs_elts &&
      !$_->parent('defs')) {

    # создаем элемент defs, если его не существует
    unless ($defs) {
      $defs = $root->insert_new_elt('defs');
      $defs->set_id('defs1');

      if ($ARGV[2] && $ARGV[2] ne "quiet") {
	print colored (" <defs", 'bold green');
	print " id=\"defs1\" (there isn't the main defs section)\n\n";
      }
    }

    # переносим этот элемент на место последнего потомка элемента defs
    $_->move(last_child => $defs);

    if ($ARGV[2] && $ARGV[2] ne "quiet") {
      print colored (" <$elt_name", 'bold magenta');
      print " id=\"$elt_id\" (into the defs section)\n\n";
    }
  }
}

# переносим первый по счету элемент defs на место первого потомка корневого элемента
$defs->move(first_child => $root) if ($defs);

# если в файле содержится несколько элементов defs, то сводим их в один
# это довольно редкое, но реально встречающееся явление
unless ($root->descendants('defs') == 1) {

  # цикл: обрабатываем все элементы defs
  foreach ($root->get_xpath("//defs")) {

    # если обрабатываемый элемент defs, не является основным, т.е. первым потомком корневого элемента, то переносим его содержимое в основной элемент defs, а сам элемент стираем
    unless ($_->cmp($defs) == 0) {
      my $defs_id = $_->id; $defs_id = "none" unless ($defs_id);

      foreach ($_->children) {
	my $elt_name = $_->name;
	my $elt_id = $_->id;
	$_->move(last_child => $defs);

	if ($ARGV[2] && $ARGV[2] ne "quiet") {
	  print colored (" <$elt_name", 'bold magenta');
	  print " id=\"$elt_id\" (into the main defs section)\n\n";
	}
      }

      $_->erase;

      if ($ARGV[2] && $ARGV[2] ne "quiet") {
	
	print colored (" <defs", 'bold red');
	print " id=\"$defs_id\" (it's not the main defs section)\n\n";
      }
    }
  }
}



#######################
# ОБРАБОТКА ЭЛЕМЕНТОВ #
#######################

print colored ("\nPROCESSING ELEMENTS\n\n", 'bold blue underline') if ($ARGV[2] && $ARGV[2] ne "quiet");


# цикл: обработка всех элементов файла
CYCLE_ELTS:
foreach my $elt ($root->descendants) {

  # получаем имя элемента
  my $elt_name = $elt->name;

  # получаем значение id элемента
  my $elt_id = $elt->id;
  $elt_id = "none" unless ($elt_id);

  # получаем префикс имени элемента
  (my $elt_pref = $elt_name)=~ s/:.+$// if ($args{'adobe_elts'} eq "delete" && $elt_name=~ /:/);


  # если обрабатываемый элемент является дочерним элементом удаленного, то пропускаем его обработку
  if ($del_id && $elt->parent("*[\@id=\"$del_id\"]")) {
    next CYCLE_ELTS;
  }


  # удаление не SVG элементов
  if ($args{'non_svgelts'} eq "delete" &&
      !$elt->is_text &&
      $elt_name!~ /:/ &&
      !($elt_name~~@svg_elts)) {

    &del_elt($elt,$elt_name,$elt_id,"it's a non-SVG element");
    next CYCLE_ELTS;
  }


  # удаление элемента metadata
  if ($args{'metadata'} eq "delete" &&
      $elt_name eq "metadata") {

    &del_elt($elt,$elt_name,$elt_id,"it's a metadata element");
    next CYCLE_ELTS;
  }


  # удаление элементов Inkscape
  if ($args{'inkscape_elts'} eq "delete" &&
      $elt_name=~ /^inkscape:/ &&
      $elt_name ne "inkscape:path-effect") {

    &del_elt($elt,$elt_name,$elt_id,"it's an Inkscape element");
    next CYCLE_ELTS;
  }


  # удаление элементов Sodipodi
  if ($args{'sodipodi_elts'} eq "delete" &&
      $elt_name=~ /^sodipodi:/) {

    &del_elt($elt,$elt_name,$elt_id,"it's a Sodipodi element");
    next CYCLE_ELTS;
  }


  # удаление элементов Adobe Illustrator
  if ($args{'adobe_elts'} eq "delete" && $elt_pref && $elt_pref~~@adobe_pref) {
    &del_elt($elt,$elt_name,$elt_id,"it's an Adobe Illustrator element");
    next CYCLE_ELTS;
  }


  # удаление элементов Adobe Illustrator (продолжение)
  if ($args{'adobe_elts'} eq "delete" &&
      $elt_name eq "foreignObject" &&
      $elt->att('requiredExtensions')~~@adobe_ns) {

    &del_elt($elt,$elt_name,$elt_id,"it's an Adobe Illustrator element");
    next CYCLE_ELTS;
  }


  # удаление невидимых элементов
  if ($args{'invisible_elts'} eq "delete") {

    # удаление элементов с атрибутом display="none"
    if ($elt->att('display') &&
	$elt->att('display') eq "none") {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }

    # удаление элементов с атрибутом opacity="0"
    if (defined $elt->att('opacity') &&
	$elt->att('opacity') == 0) {
# 	$elt->att('opacity')=~ /^-|^\+?0(\.0+)?$/) {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }

    # удаление элементов, которые не имеют ни заполнения (fill), ни обводки (stroke)
    if ($elt_name ne "g" && ($elt->att('fill') && $elt->att('fill') eq "none") ||
	(defined $elt->att('fill-opacity') && $elt->att('fill-opacity') == 0)) {
# 	(defined $elt->att('fill-opacity') && $elt->att('fill-opacity')=~ /^-|^\+?0(\.0+)?$/)) {

      if ((!$elt->att('stroke') && !$elt->parent('g[@stroke]')) ||
	  (!$elt->att('stroke') && $elt->parent("g[\@stroke=\"none\"]")) ||
	  ($elt->att('stroke') && $elt->att('stroke') eq "none") ||
	  (defined $elt->att('stroke-opacity') && $elt->att('stroke-opacity') == 0) ||
	  (defined $elt->att('stroke-width') && $elt->att('stroke-width') eq "0")) {
# 	  (defined $elt->att('stroke-opacity') && $elt->att('stroke-opacity')=~ /^-|^\+?0(\.0+)?$/) ||
# 	  (defined $elt->att('stroke-width') && $elt->att('stroke-width')=~ /^-|^\+?0(\.0+)?$unit?$/)) {

	&del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
	next CYCLE_ELTS;
      }
    }

    # удаление элементов rect, pattern и image со значением атрибутов height или width равным или меньшим нуля
    if ($elt_name~~['pattern','image', 'rect'] &&
	((defined $elt->att('height') && $elt->att('height') eq "0") ||
	(defined $elt->att('width') && $elt->att('width') eq "0"))) {
# 	((defined $elt->att('height') && $elt->att('height')=~ /^-|^\+?0(\.0+)?$unit?$/) ||
# 	(defined $elt->att('width') && $elt->att('width')=~ /^-|^\+?0(\.0+)?$unit?$/))) {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }
    elsif ($elt_name~~['pattern','image', 'rect'] &&
	   !($elt->att('height') || $elt->att('width')) &&
	   !$elt->att('xlink:href')) {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }

    # удаление элементов path с пустым атрибутом d
    if ($elt_name eq "path" &&
	!$elt->att('d')) {

	&del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
	next CYCLE_ELTS;
    }

    # удаление элементов polygon с пустым атрибутом points
    if ($elt_name eq "polygon" &&
	!$elt->att('points')) {

	&del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
	next CYCLE_ELTS;
    }

    # удаление элементов polyline с пустым атрибутом points
    if ($elt_name eq "polyline" &&
	!$elt->att('points')) {

	&del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
	next CYCLE_ELTS;
    }

    # удаление элементов circle со значением атрибута r равным или меньшим нуля
    if ($elt_name eq "circle" &&
	defined $elt->att('r') &&
	$elt->att('r') eq "0") {
# 	$elt->att('r')=~ /^-|^\+?0(\.0+)?$unit?$/) {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }

    # удаление элементов ellipse со значением атрибутов rx или ry равным или меньшим нуля
    if ($elt_name eq "ellipse" &&
	((defined $elt->att('rx') && $elt->att('rx') eq "0") ||
	(defined $elt->att('ry') && $elt->att('ry') eq "0"))) {
# 	((defined $elt->att('rx') && $elt->att('rx')=~ /^-|^\+?0(\.0+)?$unit?$/) ||
# 	(defined $elt->att('ry') && $elt->att('ry')=~ /^-|^\+?0(\.0+)?$unit?$/))) {

      &del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
      next CYCLE_ELTS;
    }

    # удаление пустых элементов text
    if ($elt_name eq "text") {

      if ($elt->children('tspan')) {
	foreach ($elt->children('tspan')) {
	  
	  $_->delete if ($_->is_empty);
	}
      }

      if ($elt->children('tref')) {
	foreach ($elt->children('tref')) {
	  
	  $_->delete if ($_->is_empty && !$_->att('xlink:href'));
	}
      }

      if ($elt->children('textPath')) {
	foreach ($elt->children('textPath')) {
	  
	  $_->delete if ($_->is_empty);
	}
      }

      if (!$elt->children &&
	  !$elt->text_only) {

	&del_elt($elt,$elt_name,$elt_id,"it's an invisible element");
	next CYCLE_ELTS;
      }
    }
  } # удаление невидимых элементов


  # удаление пустых групп (элементов g, которые не имеют дочерних элементов)
  if ($elt_name eq "g" &&
      $args{'empty_groups'} eq "delete") {

    # если группа не имеет дочерних элементов
    unless ($elt->children) {

      &del_elt($elt,$elt_name,$elt_id,"it's an empty group");
      next CYCLE_ELTS;
    }
    # или если группа имеет дочерние элементы и все они также являются группами
    elsif ($elt->children &&
	   $elt->all_children_are('g')) {

      # проверяем все дочерние группы
      foreach ($elt->children) {
	# удаляем пустую дочернюю группу
	$_->delete unless ($_->children);
      }
      # удаляем основную группу, если она стала пустой
      unless ($elt->children) {

	&del_elt($elt,$elt_name,$elt_id,"it's an empty group");
	next CYCLE_ELTS;
      }
    }
  }


  # удаляем элементы filter (Gaussian blur), у которых атрибут stdDeviation дочернего элемента feGaussianBlur меньше значения $args{'std_dev'} (по-умолчанию 0.2 - действие таких фильтров практически незаметно)
  if ($args{'gaussian_blur'} eq "delete" &&
      $elt_name eq "filter" && $elt->children_count == 1 &&
      $elt->all_children_are ('feGaussianBlur')) {

    # stdDeviation = number comma-wsp? number?
    my $stddev = $elt->first_child->att('stdDeviation');
    (my $stddevX, my $stddevY) = ($1, $2) if ($stddev=~ /^($num)$cwsp?($num)?$/);

    if (($stddevX && !$stddevY && $stddevX < $args{'std_dev'}) ||
	($stddevX && $stddevY && $stddevX < $args{'std_dev'} && $stddevY < $args{'std_dev'})) {

      &del_elt($elt,$elt_name,$elt_id,"it's an unused filter");
      next CYCLE_ELTS;
    }
  }


  # стираем элемент switch, если он не содержит атрибутов или только содержит атрибут id (в данном случае этот элемент не имеет никакого действия)
  if ($elt_name eq 'switch' &&
      ($elt->has_no_atts || ($elt->att_nb == 1 && $elt->id))) {

    $elt->erase;
    next CYCLE_ELTS;
  }


  # обработка и исправление атрибутов rx и ry в элементе rect
  if ($elt_name eq "rect" &&
      $elt->att('width') && $elt->att('height') &&
      ($elt->att('rx') || $elt->att('ry'))) {

      my $rx = $elt->att('rx');
      $rx = &units_px($elt,'rx',$1,$2) if ($rx && $rx=~ /^\s*($num)($unit)\s*$/);
      my $ry = $elt->att('ry');
      $ry = &units_px($elt,'ry',$1,$2) if ($ry && $ry=~ /^\s*($num)($unit)\s*$/);

      $rx = $ry if (!(defined $rx) && $ry);
      $ry = $rx if (!(defined $ry) && $rx);

      my $w = $elt->att('width');
      $w = &units_px($elt,'width',$1,$2) if ($w=~ /^\s*($num)($unit)\s*$/);
      my $h = $elt->att('height');
      $h = &units_px($elt,'height',$1,$2) if ($h=~ /^\s*($num)($unit)\s*$/);

      # если значение атрибута rx больше чем половина width, то устанавливаем значение rx равным половине width
      if ($rx > $w/2) {
	$rx = $w/2;
	$elt->set_att('rx' => $rx);
      }

      # если значение атрибута ry больше чем половина height, то устанавливаем значение ry равным половине height
      if ($ry > $h/2) {
	$ry = $h/2;
	$elt->set_att('ry' => $ry);
      }

      # если значения атрибутов rx и ry равны, то удаляем атрибут ry
      if ($rx == $ry) {
	$elt->set_att('rx' => $rx);
	$elt->del_att('ry');
      }

      # если одно из значений атрибутов rx и ry равно нулю, то удаляем эти атрибуты
#       if ((defined $rx && $rx=~ /^-|^\+?0(\.0+)?$/) ||
# 	  (defined $ry && $ry=~ /^-|^\+?0(\.0+)?$/)) {
      if ((defined $rx && $rx == 0) ||
	  (defined $ry && $ry == 0)) {
	$elt->del_att('rx');
	$elt->del_att('ry');
      }
  }


  # преобразование элементов basic shape в path
  if ($args{'bs_path'} eq "yes") {

    # преобразование элемента circle в path
    if ($elt_name eq "circle" && $elt->att('r')) {
      my $x = $elt->att('cx');
      my $y = $elt->att('cy');
      my $r = $elt->att('r');

      $x = 0 unless ($x);
      $y = 0 unless ($y);
      $x = &units_px($elt,'cx',$1,$2) if ($x=~ /^($num)($unit)$/);
      $y = &units_px($elt,'cy',$1,$2) if ($y=~ /^($num)($unit)$/);
      $r = &units_px($elt,'r',$1,$2) if ($r=~ /^($num)($unit)$/);

      my $x1 = $x+$r;
      my $x2 = $x-$r;

      $elt->set_tag('path');
      $elt->del_att('cx', 'cy', 'r');
#       $elt->set_att('d' => "M$x1,$y A$r,$r 0 1 0 $x2,$y A$r,$r 0 1 0 $x1,$y z");
      $elt->set_att('d' => "M$x1,$y A$r,$r 0 1 0 $x2,$y A$r,$r 0 1 0 $x1,$y");
      &bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
    }


    # преобразование элемента ellipse в path
    if ($elt_name eq "ellipse" && $elt->att('rx') && $elt->att('ry')) {
      my $x = $elt->att('cx');
      my $y = $elt->att('cy');
      my $rx = $elt->att('rx');
      my $ry = $elt->att('ry');

      $x = 0 unless ($x);
      $y = 0 unless ($y);
      $x = &units_px($elt,'cx',$1,$2) if ($x=~ /^($num)($unit)$/);
      $y = &units_px($elt,'cy',$1,$2) if ($y=~ /^($num)($unit)$/);
      $rx = &units_px($elt,'rx',$1,$2) if ($rx=~ /^($num)($unit)$/);
      $ry = &units_px($elt,'ry',$1,$2) if ($ry=~ /^($num)($unit)$/);

      my $x1 = $x+$rx;
      my $x2 = $x-$rx;

      $elt->set_tag('path');
      $elt->del_att('cx', 'cy', 'rx', 'ry');
#       $elt->set_att('d' => "M$x1,$y A$rx,$ry 0 1 0 $x2,$y A$rx,$ry 0 1 0 $x1,$y z");
      $elt->set_att('d' => "M$x1,$y A$rx,$ry 0 1 0 $x2,$y A$rx,$ry 0 1 0 $x1,$y");
      &bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
    }


    # преобразование элемента polygon в path
    if ($elt_name eq "polygon" && $elt->att('points')) {
      my $d = $elt->att('points');

      if ($d) {

	$elt->set_tag('path');
	$elt->del_att('points');
	$elt->set_att('d' => "M$d z");
	&bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
      }
    }


    # преобразование элемента polyline в path
    if ($elt_name eq "polyline" && $elt->att('points')) {
      my $d = $elt->att('points');

      if ($d) {

	$elt->set_tag('path');
	$elt->del_att('points');
	$elt->set_att('d' => "M$d");
	&bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
      }
    }


    # преобразование элемента line в path
    if ($elt_name eq "line") {
      my $x1 = $elt->att('x1');
      my $y1 = $elt->att('y1');
      my $x2 = $elt->att('x2');
      my $y2 = $elt->att('y2');

      $x1 = 0 unless ($x1);
      $y1 = 0 unless ($y1);
      $x2 = 0 unless ($x2);
      $y2 = 0 unless ($y2);
      $x1 = &units_px($elt,'x1',$1,$2) if ($x1=~ /^($num)($unit)$/);
      $y1 = &units_px($elt,'y1',$1,$2) if ($y1=~ /^($num)($unit)$/);
      $x2 = &units_px($elt,'x2',$1,$2) if ($x2=~ /^($num)($unit)$/);
      $y2 = &units_px($elt,'y2',$1,$2) if ($y2=~ /^($num)($unit)$/);

      $elt->set_tag('path');
      $elt->del_att('x1', 'y1', 'x2', 'y2');
      $elt->set_att('d' => "M$x1,$y1 $x2,$y2");
      &bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
    }


    # преобразование элемента rect в path
    if ($elt_name eq "rect" && $elt->att('height') && $elt->att('width')) {
      my $x = $elt->att('x');
      my $y = $elt->att('y');
      my $h = $elt->att('height');
      my $w = $elt->att('width');
      my $rx = $elt->att('rx');
      my $ry = $elt->att('ry');

      $x = 0 unless ($x);
      $y = 0 unless ($y);
      $rx = $ry if (!$rx && $ry);
      $ry = $rx if (!$ry && $rx);

      $x = &units_px($elt,'x',$1,$2) if ($x=~ /^($num)($unit)$/);
      $y = &units_px($elt,'y',$1,$2) if ($y=~ /^($num)($unit)$/);
      $h = &units_px($elt,'height',$1,$2) if ($h=~ /^($num)($unit)$/);
      $w = &units_px($elt,'width',$1,$2) if ($w=~ /^($num)($unit)$/);
      $rx = &units_px($elt,'rx',$1,$2) if ($rx && $rx=~ /^($num)($unit)$/);
      $ry = &units_px($elt,'ry',$1,$2) if ($ry && $ry=~ /^($num)($unit)$/);

      $elt->set_tag('path');
      $elt->del_att('x', 'y', 'rx', 'ry', 'height', 'width');

      unless ($rx && $ry) {
	my $x1 = $x+$w;
	my $y1 = $y+$h;
	$elt->set_att('d' => "M$x,$y H$x1 V$y1 H$x z");
      } else {
	my $x1 = $x+$rx;
	my $x2 = $x+$w-$rx;
	my $x3 = $x+$w;
	my $y1 = $y+$ry;
	my $y2 = $y+$h-$ry;
	my $y3 = $y+$h;
	$elt->set_att('d' => "M$x1,$y H$x2 A$rx,$ry 0 0 1 $x3,$y1 V$y2 A$rx,$ry 0 0 1 $x2,$y3 H$x1 A$rx,$ry 0 0 1 $x,$y2 V$y1 A$rx,$ry 0 0 1 $x1,$y");
      }
      &bs_path($elt_name,$elt_id) if ($ARGV[2] && $ARGV[2] ne "quiet");
    }
  }


  # если группа и все входящие в нее элементы содержат атрибут transform, то производим перерасчет этих атрибутов у дочерних элементов, а атрибут группы удаляем после перерасчета
  if ($args{'conc_trans'} eq "yes" &&
      $elt_name eq "g" && !($twig->get_xpath("//*[\@xlink:href=\"#$elt_id\"]")) &&
      $elt->att('transform') && $elt->children &&
      $elt->all_children_are('*[@transform]')) {

    unless ($elt->att('mask') ||
	    $elt->att('clip-path') ||
	    $elt->att('filter') ||
	    $elt->descendants('use') ||
	    ($elt->att('fill') && $elt->att('fill')=~ /^url/) ||
	    ($elt->att('stroke') && $elt->att('stroke')=~ /^url/)) {

      my $matrix1 = $elt->att('transform');

      if ($ARGV[2] && $ARGV[2] ne "quiet") {

      print colored (" <g",'bold'); print " id=$elt_id\n";
      print colored ("  •transform=$matrix1\n",'red');
      }

      $matrix1 = &trans_matrix($matrix1) unless ($matrix1=~ /^$matrix$/);
      $elt->del_att('transform');

      foreach ($elt->children) {

	my $ch_name = $_->name;
	my $ch_id = $_->id;

	my $matrix2 = $_->att('transform');
	$matrix2 = &trans_matrix($matrix2) unless ($matrix2=~ /^$matrix$/);

	$matrix2 = &nested_transform($matrix1,$matrix2);

	$_->set_att('transform' => $matrix2);

	if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored ("   <$ch_name",'bold'); print " id=$ch_id\n";
	print colored ("    •transform=$matrix2\n",'green');
	}
      }
	print "\n" if ($ARGV[2] && $ARGV[2] ne "quiet");
    }
  }


####################
# ОБРАБОТКА ССЫЛОК #
####################

  # если удаляются неиспользуемые элементы из секции defs и/или неиспользуемые id и предком обрабатываемого элемента не является defs
  if (($args{'unused_def'} eq "delete" || $args{'unref_id'} eq "delete") &&
      !$elt->parent('defs')) {

    # обрабатываем все атрибуты этого элемента
    while ((my $att, my $att_val) = each %{$elt->atts}) {

      # если атрибут содержит ссылку на другой элемент
      if ($att_val =~ /^url\(#(.+)\)$/ ||
	  ($att eq "xlink:href" && $att_val =~ /^#(.+)$/)) {

	# если ссылка указывает на удаленный элемент или на несуществующий id, то удаляем атрибут, содержащий эту ссылку
	if ($1 ~~ @del_elts || !$twig->elt_id($1)) {

	  $elt->del_att($att);

	  if ($att eq "fill") {

	    $elt->set_att('fill' => 'none');

	    if ((!$elt->att('stroke') && !$elt->parent('g[@stroke]')) ||
	    (!$elt->att('stroke') && $elt->parent("g[\@stroke=\"none\"]")) ||
	    ($elt->att('stroke') && $elt->att('stroke') eq "none") ||
	    (defined $elt->att('stroke-opacity') && $elt->att('stroke-opacity')=~ /^-|^\+?0(\.0+)?$/) ||
	    (defined $elt->att('stroke-width') && $elt->att('stroke-width')=~ /^-|^\+?0(\.0+)?$unit?$/)) {

	    $elt->delete;
	    }
	  }
# 	  $elt->set_att('fill' => 'none') if ($att eq "fill");
# 	  $elt->delete if ($att eq "fill" && !$elt->att('stroke') && !$elt->parent('g[@stroke]'));
# 	  $elt->delete if ($att eq "fill" && $elt->att('stroke') eq "none");
# 	  $elt->delete if ($att eq "fill" && $elt->att('stroke-width') && $elt->att('stroke-width')=~ /^-|^0$unit?$/);
	} else {
	  # в противном случае записываем ссылку в массив @ref_id (если соответствующего id еще нет в этом массиве)
	  push @ref_id, $1 unless ($1 ~~ @ref_id);
	}
      }
    }
  }
} # УДАЛЕНИЕ ЭЛЕМЕНТОВ

# массив внешних ссылок
my @out_link = @ref_id;


########################
# ЧИСТКА ЭЛЕМЕНТА DEFS #
########################

if ($args{'unused_def'} eq "delete" ||
    $args{'unref_id'} eq "delete") {

  # цикл: обрабатываем все id из массива @ref_id
  foreach (@ref_id) {
    # цикл: обрабатываем элемент с текущим id и всех его потомков (поскольку они также могут содержать ссылки на другие элементы, как, например, дочерние элементы path у элементов clipPath или mask)
    foreach my $elt ($twig->elt_id("$_")->descendants_or_self){

      # цикл: обрабатываем атрибуты текущего элемента
      while ((my $att, my $att_val) = each %{$elt->atts}) {

	# если атрибут содержит ссылку на другой элемент
	if ($att_val =~ /^url\(#(.+)\)$/ ||
	    ($att eq "xlink:href" && $att_val =~ /^#(.+)$/)) {

	  # если ссылка указывает на удаленный элемент или на несуществующий id, то удаляем атрибут, содержащий эту ссылку
	  if ($1 ~~ @del_elts ||
	      !($twig->elt_id($1))) {

	    $elt->del_att($att);
	  }
	  # если ссылки еще нет в массиве @ref_id и элемент 'use' имеет родителя 'clipPath', а ссылка берется из атрибута 'xlink:href', то записываем ссылку в массив @ref_id
	  elsif (!($1 ~~ @ref_id) &&
		 $args{'clip_atts'} eq "delete" && $elt->parent('clipPath') &&
		 $elt->name('use') && $att eq "xlink:href") {

	    push @ref_id, $1;
	  }
	  # если ссылки еще нет в массиве @ref_id и отключена опция удаления неиспользующихся атрибутов у дочерних элементов элемента clipPath, то записываем ссылку в массив @ref_id
	  elsif (!($1 ~~ @ref_id) && 
		 !($args{'clip_atts'} eq "delete" && $elt->parent('clipPath'))) {

	    push @ref_id, $1;
	  }
	}
      } # цикл: обрабатываем атрибуты текущего элемента
    } # цикл: обрабатываем элемент с текущим id, а также всех его потомков
  } # цикл: перебираем все id из массива @ref_id
}


if ($args{'unused_def'} eq "delete" && $defs) {

  # цикл: обрабатываем все дочерние элементы элемента defs
  foreach my $elt ($defs->children) {

    # получаем имя id обрабатываемого элемента
    my $elt_id = $elt->id;
#     $elt_id = "none" unless ($elt_id);

    # удаляем элемент, если его имя не "style" и id не содержится в массиве @ref_id (списке id на которые имеются ссылки)
    if ($elt->name ne "style" && $elt_id && !($elt_id~~@ref_id)) {

      # бывают случаи, когда сам элемент не содержится в списке id на которые имеются ссылки, а его потомки - содержатся
      if ($elt->children) {
	foreach ($elt->descendants) {
	  # переносим такого потомка удаляемого элемента на место последнего потомка элемента defs
	  $_->move(last_child => $defs) if (($_->id)~~@ref_id);
	}
      }

      my $elt_name = $elt->name;
      &del_elt($elt,$elt_name,$elt_id,"it's an unused definition");
    }
  }
}


# удаляем пустую секцию defs
if ($args{'empty_defs'} eq "delete" &&
    $defs && !$defs->children) {

  my $elt_id = $defs->id; $elt_id = "none" unless ($elt_id);
  &del_elt($defs,"defs",$elt_id,"it's the empty defs section");
}


# поиск и удаление дубликатов элементов из секции defs - первый проход
if ($args{'dupl_defs'} eq "yes" && $defs) {

  # обработка всех элементов из секции defs
  foreach my $elt ($defs->children) {

    # получаем имя элемента
    my $elt_name = $elt->name;
    # получаем id элемента
    my $elt_id = $elt->id;

    # если существует id элемента
    if ($elt_id) {

      # получаем описание элемента
      my $desc = &desc_elt($elt);

      # если описание элемента уже существует
      if (exists($desc_elts{$desc})) {

	# добавляем id элемента в хэш ссылок идентичных элементов, а сам элемент удаляем
	$comp_elts{$elt_id} = $desc_elts{$desc};
	$elt->delete;

	if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored (" <$elt_name", 'bold red');
	print " id=\"$elt_id\" (it's a duplicated element)\n\n";
	}
      } else {

	# если нет, то добавляем описание элемента в хэш описания элементов секции defs
	$desc_elts{$desc} = $elt_id;
      }
    }
  }
  # очищаем хэш описания элементов секции defs для экономии памяти
  %desc_elts = ();
}


# пересчитываем координаты и удаляем атрибут gradientTransform
# во избежание искажений обрабатываем только следующие виды трансформаций:
# matrix(a,0,0,d,0,0) - масштабирование
# matrix(1,0,0,1,e,f) - перемещение
# matrix(a,0,0,d,e,f) - масштабирование и перемещение
# (x,y) = (ax+e, dy+f) - формула расчета новых координат
if ($args{'opt_trans'} eq "yes" && $defs) {

  foreach my $elt ($defs->get_xpath('./*[@gradientTransform]')) {

    my $elt_name = $elt->name;
    my $elt_id = $elt->id;
    my $trans = $elt->att('gradientTransform');
    my $grad_trans = $trans;

    # преобразовываем трансформацию в матрицу трансформации
    unless ($trans=~/^$matrix$/) {

      $trans = &trans_matrix($trans);
    }

    # обрабатываем линейные градиенты
    if ($elt_name eq "linearGradient" &&
	$trans!~/$scinum/ &&
	$trans=~/^$matrix$/ &&
	$2 == 0 && $3 == 0) {

      (my $a,my $d,my $e,my $f) = ($1,$4,$5,$6);

      my $x1 = $elt->att('x1');
      my $x2 = $elt->att('x2');
      my $y1 = $elt->att('y1');
      my $y2 = $elt->att('y2');

      $x1 = 0 unless ($x1);
      $x2 = "100%" unless ($x2);
      $y1 = 0 unless ($y1);
      $y2 = 0 unless ($y2);

      $x1 = &units_px($elt,'x1',$1,$2) if ($x1=~ /^($num)($unit)$/);
      $x2 = &units_px($elt,'x2',$1,$2) if ($x2=~ /^($num)($unit)$/);
      $y1 = &units_px($elt,'y1',$1,$2) if ($y1=~ /^($num)($unit)$/);
      $y2 = &units_px($elt,'y2',$1,$2) if ($y2=~ /^($num)($unit)$/);

      (my $x11,my $x22,my $y11,my $y22) = ($a*$x1+$e,$a*$x2+$e,$d*$y1+$f,$d*$y2+$f);

      if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored (" <$elt_name", 'bold');
	print " id=$elt_id:\n";
	print colored ("  •gradientTransform=$grad_trans\n", 'red');
	print colored ("  •x1=$x1\n", 'red');
	print colored ("  •x2=$x2\n", 'red');
	print colored ("  •y1=$y1\n", 'red');
	print colored ("  •y2=$y2\n", 'red');

	print colored ("  •x1=$x11\n", 'green');
	print colored ("  •x2=$x22\n", 'green');
	print colored ("  •y1=$y11\n", 'green');
	print colored ("  •y2=$y22\n", 'green');
	print "\n";
      }

      $elt->set_att('x1' => $x11);
      $elt->set_att('x2' => $x22);
      $elt->set_att('y1' => $y11);
      $elt->set_att('y2' => $y22);
      $elt->del_att('gradientTransform');
      push @{ $rem_gratts{$elt_id} }, "gradientTransform";
    } # linearGradient

    # обрабатываем радиальные градиенты
    if ($elt_name eq "radialGradient" &&
	$trans!~/$scinum/ &&
	$trans=~/^$matrix$/ &&
	$2 == 0 && $3 == 0 && $1 == $4) {

      (my $a,my $d,my $e,my $f) = ($1,$4,$5,$6);

      my $cx = $elt->att('cx');
      my $cy = $elt->att('cy');
      my $fx = $elt->att('fx');
      my $fy = $elt->att('fy');
      my $r = $elt->att('r');

      $cx = "50%" unless ($cx);
      $cy = "50%" unless ($cy);
      $r = "50%" unless ($r);

      $cx = &units_px($elt,'cx',$1,$2) if ($cx && $cx=~ /^($num)($unit)$/);
      $cy = &units_px($elt,'cy',$1,$2) if ($cy && $cy=~ /^($num)($unit)$/);
      $fx = &units_px($elt,'fx',$1,$2) if ($fx && $fx=~ /^($num)($unit)$/);
      $fy = &units_px($elt,'fy',$1,$2) if ($fy && $fy=~ /^($num)($unit)$/);
      $r = &units_px($elt,'r',$1,$2) if ($r && $r=~ /^($num)($unit)$/);

      my $r1 = $r*$a;
      my $cx1 = $a*$cx+$e;
      my $fx1 = $a*$fx+$e if ($fx);
      my $cy1 = $d*$cy+$f;
      my $fy1 = $d*$fy+$f if ($fy);

      if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored (" <$elt_name", 'bold');
	print " id=$elt_id:\n";
	print colored ("  •gradientTransform=$grad_trans\n", 'red');
	print colored ("  •cx=$cx\n", 'red');
	print colored ("  •cy=$cy\n", 'red');
	print colored ("  •fx=$fx\n", 'red') if ($fx);
	print colored ("  •fy=$fy\n", 'red') if ($fy);
	print colored ("  •r=$r\n", 'red');

	print colored ("  •cx=$cx1\n", 'green');
	print colored ("  •cy=$cy1\n", 'green');
	print colored ("  •fx=$fx1\n", 'green') if ($fx);
	print colored ("  •fy=$fy1\n", 'green') if ($fy);
	print colored ("  •r=$r1\n", 'green');
	print "\n";
      }

      $elt->set_att('cx' => $cx1);
      $elt->set_att('cy' => $cy1);
      $elt->set_att('fx' => $fx1) if ($fx);
      $elt->set_att('fy' => $fy1) if ($fy);
      $elt->set_att('r' => $r1);
      $elt->del_att('gradientTransform');
      push @{ $rem_gratts{$elt_id} }, "gradientTransform";
    } # radialGradient
  } #цикл
}



#######################
# ОБРАБОТКА АТРИБУТОВ #
#######################

print colored ("\nPROCESSING ATTRIBUTES\n\n", 'bold blue underline') if ($ARGV[2] && $ARGV[2] ne "quiet");


# цикл: обработка всех элементов файла
foreach my $elt ($root->descendants_or_self) {

  $i = 0;

  # получаем имя элемента
  my $elt_name = $elt->name;

  # получаем префикс имени элемента
  (my $elt_pref = $elt_name)=~ s/:.+$// if ($args{'adobe_atts'} eq "delete" && $elt_name=~ /:/);

  # получаем id элемента
  my $elt_id = $elt->id;
  $elt_id = "none" unless ($elt_id);


  # создаем атрибут viewBox
  if ($args{'viewbox'} eq "yes" &&
      $elt_name eq "svg") {

    if (!$root->att('viewBox')) {

      $root->set_att('viewBox' => "0 0 $actual_width $actual_height");
      &crt_att($elt,"viewBox","\"0 0 $actual_width $actual_height\"",$i,$elt_name,$elt_id);
      &del_att($elt,"height","viewBox is enabled",$i,$elt_name,$elt_id);
      &del_att($elt,"width","viewBox is enabled",$i,$elt_name,$elt_id);
    }
    elsif ($root->att('viewBox') &&
	   $root->att('height') && $root->att('width') &&
	   $root->att('viewBox')=~ /($num)\s*,?\s*($num)$/ &&
	   $1 == $actual_width && $2 == $actual_height) {

      &del_att($elt,"height","viewBox is enabled",$i,$elt_name,$elt_id);
      &del_att($elt,"width","viewBox is enabled",$i,$elt_name,$elt_id);
    }
  }


  # цикл: обработка всех атрибутов текущего элемента
  CYCLE_ATTS:
  foreach my $att ($elt->att_names) {

    next CYCLE_ATTS unless ($att);


    # удаление не SVG атрибутов
    if ($args{'non_svgatts'} eq "delete" &&
	$att!~ /:/ &&
	!($att~~@present_atts) &&
	!($att~~@regular_atts)) {

      &del_att($elt,$att,"it's a non-SVG attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # удаление атрибутов, которые не используются элементом в котором они находятся
    if ($args{'nonspec_atts'} eq "delete") {

      # удаление атрибутов Regular attributes, если они находятся в элементе, который их не использует
      if (exists($reg_atts{$att}) &&
	  !($elt_name~~$reg_atts{$att})) {

	&del_att($elt,$att,"this attribute is not applied to the element",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      # удаление атрибутов Presentation attributes, если они находятся в элементе, который их не использует (быстрая проверка)
      if ($att~~@present_atts &&
	  !($elt_name~~@present_elts)) {

	&del_att($elt,$att,"this attribute is not applied to the element",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      # удаление атрибутов Presentation attributes, если они находятся в элементе, который их не использует (более тщательная проверка)
      if (exists($pres_atts{$att}) &&
	  !($elt_name~~$pres_atts{$att})) {

	&del_att($elt,$att,"this attribute is not applied to the element",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      # удаление атрибута clip-rule, если его предком или потомком не является элемент clipPath
      # "this attribute is not applied to the element" - этот атрибут не применяется к элементу
      if ($att eq "clip-rule" &&
	  !($elt_name eq "clipPath" || $elt->children('clipPath') || $elt->parent('clipPath'))) {

	&del_att($elt,'clip-rule',"this attribute is not applied to the element",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;	
      }

      # удаление текстовых атрибутов у всех элементов, кроме text, а также его предков и потомков
      if ($att~~@text_atts &&
	  !($elt_name eq "text" || $elt->parent('text') || $elt->descendants('text'))) {

	  &del_att($elt,$att,"this attribute is not applied to the element",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
      }
    } # удаление атрибутов, которые не используются элементом в котором они находятся


    # получаем значение атрибута
    my $att_val = $elt->att($att);


    # получаем префикс имени атрибута
    (my $att_pref = $att)=~ s/:.+$// if ($args{'adobe_atts'} eq "delete" && $att=~ /:/);


    # удаление неиспользуемых имен id
    if ($args{'unref_id'} eq "yes" &&
	$att eq "id" &&
	!($att_val ~~ @ref_id)) {

      next CYCLE_ATTS if ($args{'protect_id'} eq "yes" && $att_val=~ /^[a-zA-Z]+$/);

      &del_att($elt,$att,"it's an unreferenced id",$i,$elt_name,$elt_id);
      next CYCLE_ATTS; 
    }


    # удаление неиспользуемых пространств имен
    if ($args{'unused_ns'} eq "delete" &&
	$att=~ /^xmlns:/) {

      # удаление пространств имен metadata
      if ($args{'metadata'} eq "delete" &&
	  $att~~['xmlns:rdf','xmlns:cc','xmlns:dc']) {

	&del_att($elt,$att,"it's an unused namespace",$i,$elt_name,$elt_id);
	next CYCLE_ATTS; 
      }

      # удаление пространств имен Inkscape, если в файле отсутствуют элементы inkscape:path-effect
      if ($args{'inkscape_elts'} eq "delete" &&
	  $args{'inkscape_atts'} eq "delete" &&
	  !($root->descendants('inkscape:path-effect')) &&
	  $att eq "xmlns:inkscape") {

	&del_att($elt,$att,"it's an unused namespace",$i,$elt_name,$elt_id);
	next CYCLE_ATTS; 
      }

      # удаление пространств имен Sodipodi
      if ($args{'sodipodi_elts'} eq "delete" &&
	  $args{'sodipodi_atts'} eq "delete" &&
	  $att eq "xmlns:sodipodi") {

	&del_att($elt,$att,"it's an unused namespace",$i,$elt_name,$elt_id);
	next CYCLE_ATTS; 
      }

      # удаление пространств имен Adobe Illustrator
      if ($args{'adobe_elts'} eq "delete" &&
	  $args{'adobe_atts'} eq "delete" &&
	  $att_val~~@adobe_ns) {

	&del_att($elt,$att,"it's an unused namespace",$i,$elt_name,$elt_id);
	next CYCLE_ATTS; 
      }

      # удаление пространства имен xlink
      if ($att eq "xmlns:xlink" &&
	  !$twig->get_xpath('//*[@xlink:href or @xlink:type or @xlink:role or @xlink:arcrole or @xlink:title or @xlink:show or @xlink:actuate]')) {

	&del_att($elt,$att,"it's an unused namespace",$i,$elt_name,$elt_id);
	next CYCLE_ATTS; 
      }
    } # удаление неиспользуемых пространств имен


    # удаление атрибутов Inkscape
    if ($args{'inkscape_elts'} ne "delete" &&
	$args{'inkscape_atts'} eq "delete" &&
	$elt_name!~ /^inkscape:/ &&
	$att=~ /^inkscape:/) {

      &del_att($elt,$att,"it's an Inkscape attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }
    elsif ($args{'inkscape_elts'} eq "delete" &&
	   $args{'inkscape_atts'} eq "delete" &&
	   $elt_name ne "inkscape:path-effect" &&
	   $att=~ /^inkscape:/) {

      &del_att($elt,$att,"it's an Inkscape attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # удаление атрибутов Sodipodi
    if ($args{'sodipodi_elts'} ne "delete" &&
	$elt_name!~ /^sodipodi:/ &&
	$args{'sodipodi_atts'} eq "delete" &&
	$att=~ /^sodipodi:/) {

      &del_att($elt,$att,"it's a Sodipodi attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }
    elsif ($args{'sodipodi_elts'} eq "delete" &&
	   $args{'sodipodi_atts'} eq "delete" &&
	   $att=~ /^sodipodi:/) {

      &del_att($elt,$att,"it's a Sodipodi attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # удаление атрибутов Adobe Illustrator
    if ($args{'adobe_elts'} ne "delete" &&
	$args{'adobe_atts'} eq "delete" &&
	$att_pref && $att_pref~~@adobe_pref &&
	!($elt_pref~~@adobe_pref)) {

      &del_att($elt,$att,"it's an Adobe Illustrator attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }
    elsif ($args{'adobe_elts'} eq "delete" &&
	   $args{'adobe_atts'} eq "delete" &&
	   $att_pref && $att_pref~~@adobe_pref) {

      &del_att($elt,$att,"it's an Adobe Illustrator attribute",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    #  удаление атрибутов определяющих обводку (stroke), если обводка отсутствует (stroke отсутствует ИЛИ stroke=none ИЛИ stroke-opacity=0 ИЛИ stroke-width=0)
    if ($args{'stroke_atts'} eq "delete" &&
	$att=~ /^stroke-/) {

      if ((!$elt->att('stroke') && !$elt->parent('[@stroke]')) ||
	  (!$elt->att('stroke') && $elt->parent("[\@stroke=\"none\"]")) ||
	  ($elt->att('stroke') && $elt->att('stroke') eq "none")) {

	&del_att($elt,$att,"this element is not stroked",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      if ((defined $elt->att('stroke-opacity') && $elt->att('stroke-opacity') == 0) ||
	  (defined $elt->att('stroke-width') && $elt->att('stroke-width')=~ /^0$/)) {

	&del_att($elt,$att,"this element is not stroked",$i,$elt_name,$elt_id);
	if (!$elt->parent('[@stroke]') ||
	    $elt->parent("[\@stroke=\"none\"]")) {
	  &del_att($elt,'stroke',"this element is not stroked",$i,$elt_name,$elt_id);
	} else {
	  $elt->set_att('stroke' => 'none');
	}
	next CYCLE_ATTS;
      }
    }


    #  удаление атрибутов определяющих заполнение (fill), если заполнение отсутствует (fill=none ИЛИ fill-opacity=0)
    if ($args{'fill_atts'} eq "delete" &&
	$att=~ /^fill-/) {

      if (($elt->att('fill') && $elt->att('fill') eq "none") ||
	  (!$elt->att('fill') && $elt->parent("[\@fill=\"none\"]"))) {

	&del_att($elt,$att,"this element is not filled",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      if (defined $elt->att('fill-opacity') && $elt->att('fill-opacity') == 0) {

	&del_att($elt,$att,"this element is not filled",$i,$elt_name,$elt_id);
	$elt->set_att('fill' => 'none') unless ($elt->parent("[\@fill=\"none\"]"));
	next CYCLE_ATTS;
      }
    }


    # удаление неиспользующихся атрибутов у всех потомков элемента clipPath
    if ($args{'clip_atts'} eq "delete" &&
	$elt->parent('clipPath') && !($att~~@clip_atts)) {

	&del_att($elt,$att,"it's not a clipPath used attribute",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
    }


    ###############################################################################
    # перерасчет значения атрибута в зависимости от его еденицы измерения (юнита) #
    ###############################################################################
    if ($args{'units_px'} eq "yes" &&
	$att_val=~ /^($num)($unit)$/) {

      # первоначальное значение атрибута
      my $old_att = $att_val;

      $att_val = $actual_width if ($elt_name eq "svg" && $att eq "width");
      $att_val = $actual_height if ($elt_name eq "svg" && $att eq "height");

      # новое значение атрибута
      $att_val = &units_px($elt,$att,$1,$2) unless ($elt_name eq "svg");

      # сохраняем значение атрибута, если оно было изменено
      if ("$att_val" ne "$old_att") {
	$elt->set_att($att => $att_val);
	&crt_att($elt,$att,"\"$old_att\" => \"$att_val\"",$i,$elt_name,$elt_id);
      }
    }


    ##########################################
    # округление цифровых значений атрибутов #
    ##########################################
    if ($args{'round_numbers'} eq "yes" &&
	$elt_name ne "svg" &&
	$att_val=~ /\./ &&
	$att_val=~ /^($fpnum)($unit)?$/) {

      my $number = $1;
      my $unit = $2;

      # первоначальное значение атрибута
      my $old_att = $att_val;

      # новое значение атрибута
      if ($att=~ /[Hh]eight$|[Ww]idth$|^[xy]$|^[cdfr][xy]$|^[xy][12]$|^r$|^ref[XY]$/) {

	$att_val = &round_num($number,$unit,$args{'dp_d'});
      } else {

	$att_val = &round_num($number,$unit,$args{'dp_att'});
      }

      # сохраняем значение атрибута, если оно было изменено
      if ("$att_val" ne "$old_att") {
	$elt->set_att($att => $att_val);
	&crt_att($elt,$att,"\"$old_att\" => \"$att_val\"",$i,$elt_name,$elt_id);
      }
    }


    # обработка атрибутов цвета
    if ($args{'color_rrggbb'} eq "yes" &&
	$att=~ /^fill$|^stroke$|color$/ &&
	$att_val!~ /^#([\da-f]){3}$|^url\(#/) {

      # первоначальное значение атрибута
      my $old_att = $att_val;

      # новое значение атрибута
      $att_val = &color_rrggbb($att_val,$args{'color_rgb'});

      # сохраняем значение атрибута, если оно было изменено
      if ("$att_val" ne "$old_att") {
	$elt->set_att($att => $att_val);
	&crt_att($elt,$att,"\"$old_att\" => \"$att_val\"",$i,$elt_name,$elt_id);
      }

      if ($args{'default_atts'} ne "delete" &&
	  (($att ne "lighting-color" && $att_val!~/^#fff(fff)?$/) || $att_val!~/^#000(000)?$/)) {
	next CYCLE_ATTS;
      }
    }


    # удаление атрибутов с дефолтными значениями
    if ($args{'default_atts'} eq "delete" &&
	exists($default_atts{$att})) {

      if ($att eq "lighting-color" &&
	  $att_val=~ /^white$|^rgb\s*\(\s*(255|100%)\s*,\s*(255|100%)\s*,\s*(255|100%)\s*\)$|^#fff$/i) {

	$att_val = "#ffffff";
      }
      elsif ($att=~ /^color$|^fill$|^flood-color$|^stop-color$|^solid-color$/ &&
	     $att_val=~ /^black$|^rgb\s*\(\s*0%?\s*,\s*0%?\s*,\s*0%?\s*\)$|^#000$/i) {

	$att_val = "#000000";
      }

      # не удаляем дефолтное значение атрибута fill, если содержащий его элемент находится в секции defs
      if ($att_val eq $default_atts{$att} &&
	  $att eq "fill" &&
	  $elt_name~~@keep_fill &&
	  $elt->parent('defs')) {

	next CYCLE_ATTS;
      }

      # не удаляем дефолтное значение атрибута, если родительский элемент его элемента аналогичный атрибут
      if ($att!~ /opacity$/ &&
	  $att_val eq $default_atts{$att} &&
	  $elt->parent("[\@$att]")) {

	next CYCLE_ATTS;
      }


      if ($att_val eq $default_atts{$att}) {

	&del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }
    }


    # удаление атрибутов с дефолтными значениями (продолжение)
    if ($args{'default_atts'} eq "delete") {

      if ($elt_name eq 'linearGradient') {
	if (($att~~['x1','y1','y2'] && $att_val=~/^[-+]?0(\.0+)?$unit?$/) ||
	    ($att eq "gradientUnits" && $att_val eq 'objectBoundingBox') ||
	    ($att eq "spreadMethod" && $att_val eq 'pad')) {

	  push @{ $rem_gratts{$elt_id} }, $att;
	  &del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }

      if ($elt_name eq 'radialGradient') {
	if (($att eq "gradientUnits" && $att_val eq 'objectBoundingBox') ||
	    ($att eq "spreadMethod" && $att_val eq 'pad')) {

	  push @{ $rem_gratts{$elt_id} }, $att;
	  &del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }

      if ($elt_name eq 'pattern') {
	if (($att~~['x','y'] && $att_val=~/^[-+]?0(\.0+)?$unit?$/) ||
	    ($att eq "patternUnits" && $att_val eq 'objectBoundingBox') ||
	    ($att eq "patternContentUnits" && $att_val eq 'userSpaceOnUse')) {

	  &del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }

      if ($elt_name eq 'rect' &&
	  $att~~['x','y'] &&
	  $att_val=~/^[-+]?0(\.0+)?$unit?$/) {

	&del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      if ($elt_name~~['circle','ellipse'] &&
	  $att~~['cx','cy'] &&
	  $att_val=~/^[-+]?0(\.0+)?$unit?$/) {

	&del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      if ($elt_name eq 'line' &&
	  $att~~['x1','x2','y1','y2'] &&
	  $att_val=~/^[-+]?0(\.0+)?$unit?$/) {

	&del_att($elt,$att,"\"$att_val\" is the default value for this attribute",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }
    }


    # удаление координат у градиентов
    if ($args{'grad_coord'} eq "yes") {

      # обработка атрибутов x1 и x2 элемента linearGradient
      if ($elt_name eq "linearGradient" &&
	  $att eq "x2") {

	my $x1 = $elt->att('x1');
	$x1 = 0 unless ($x1);

	# если x2 равен x1, то удаляем x1, а x2 устанавливаем равным 0
	if ("$att_val" eq "$x1") {

	  push @{ $rem_gratts{$elt_id} }, "x1";
	  &del_att($elt,"x1","\'x1\' and \'x2\' are equal",$i,$elt_name,$elt_id);
	  &crt_att($elt,$att,"\"$att_val\" => \"0\"",$i,$elt_name,$elt_id);
	  $elt->set_att($att => '0');
	  next CYCLE_ATTS;
	}
      }


      # обработка атрибутов y1 и y2 элемента linearGradient
      if ($elt_name eq "linearGradient" &&
	  $att eq "y2") {

	my $y1 = $elt->att('y1');
	$y1 = 0 unless ($y1);

	# если y2 равен y1, то удаляем их обоих
	if ("$att_val" eq "$y1") {

	  push @{ $rem_gratts{$elt_id} }, "y1", "y2";
	  &del_att($elt,"y1","\'y1\' and \'y2\' are equal",$i,$elt_name,$elt_id);
	  &del_att($elt,"y2","\'y1\' and \'y2\' are equal",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }


      # обработка атрибутов fx и cx элемента radialGradient
      if ($elt_name eq "radialGradient" &&
	  $att eq "fx") {

	my $cx = $elt->att('cx');
	$cx = "50%" unless ($cx);

	# если fx равен cx, то удаляем fx
	if ("$att_val" eq "$cx") {

	  push @{ $rem_gratts{$elt_id} }, "fx";
	  &del_att($elt,$att,"\'fx\' and \'cx\' are equal",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }


      # обработка атрибутов fy и cx элемента radialGradient
      if ($elt_name eq "radialGradient" &&
	  $att eq "fy") {

	my $cy = $elt->att('cy');
	$cy = "50%" unless ($cy);

	# если fx равен cx, то удаляем fx
	if ("$att_val" eq "$cy") {

	  push @{ $rem_gratts{$elt_id} }, "fy";
	  &del_att($elt,$att,"\'fy\' and \'cy\' are equal",$i,$elt_name,$elt_id);
	  next CYCLE_ATTS;
	}
      }
    }


    # преобразование абсолютных координат в относительные в атрибуте d
    if ($att eq "d" &&
	$args{'abs_rel'} eq "yes" &&
	$att_val=~ /[MZLHVCSQTA]/) {

      # ПРАВИЛО РЕНДЕРИНГА: обработка команд и их параметров производится до выявления первой же ошибки (после нее путь дальше уже не отрисовывается)

      # создаем массив с командами и их параметрами 
      my @d = split(/([MZLHVCSQTAmzlhvcsqta])/, $att_val);

      # новые данные path
      my $d;
      # последняя команда из новой строки path
      my $rcmd;
      # текущие абсолютные координаты X и Y
      my $cpX; my $cpY;
      # абсолютные координаты X и Y последней команды "moveto" (к этим координатам осуществляется переход после команды "closepath")
      my $mX; my $mY;
      # текущие относительные координаты X и Y
      my $dx; my $dy;
      # координаты для кривых Безье
      my $dx1; my $dy1; my $dx2; my $dy2;
      # параметры дуг
      my $rx; my $ry; my $xar; my $laf; my $sf;

      # цикл обработки обработки данных текущего элемента path
      CYCLE_D:
      while (@d) {
	# берем команду
	my $cmd = shift @d;

	# обрабатываем команду "closepath": Z|z
	if ($cmd~~['Z', 'z']) {
	  ($cpX, $cpY) = ($mX, $mY);
	  $d = $d."z";
	  $rcmd = "z";
	}

	# обрабатываем команду "moveto": M|m (x y)+
	elsif ($cmd~~['M', 'm']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # обнуляем значение переменной $rcmd  
	  undef $rcmd;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$/) {
	      # у самой первой команды "moveto" координаты всегда абсолютные
	      if (!$d && !$data) {
		($dx, $dy, $cpX, $cpY) = ($1, $2, $1, $2);
	      }
	      else {
		($dx, $dy, $cpX, $cpY) = ($1-$cpX, $2-$cpY, $1, $2) if ($cmd eq "M");
		($dx, $dy, $cpX, $cpY) = ($1, $2, $cpX+$1, $cpY+$2) if ($cmd eq "m");
	      }

	      # округляем относительные координаты
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($args{'round_numbers'} eq "yes" && $dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($args{'round_numbers'} eq "yes" && $dy=~ /\./);

	      if (!$rcmd) {
		($mX, $mY) = ($cpX, $cpY);
		$data = $data."m$dx,$dy";
		$rcmd = "m";
	      }
	      elsif ($rcmd~~['m','l'] && $dx && $dy) {
		$data = $data." $dx,$dy";
		$rcmd = "l";
	      }
	      elsif ($rcmd~~['h','v'] && $dx && $dy) {
		$data = $data."l$dx,$dy";
		$rcmd = "l";
	      }
	      elsif ($rcmd~~['m','l','v'] && $dx && !$dy) {
		$data = $data."h$dx";
		$rcmd = "h";
	      }
	      elsif ($rcmd eq "h" && $dx && !$dy) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dx += $1;
		$data = $data." $dx";
		$rcmd = "h";
	      }
	      elsif ($rcmd~~['m','l','h'] && !$dx && $dy) {
		$data = $data."v$dy";
		$rcmd = "v";
	      }
	      elsif ($rcmd eq "v" && !$dx && $dy) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dy += $1;
		$data = $data." $dy";
		$rcmd = "v";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# обрабатываем команду "lineto": L|l (x y)
	elsif ($cmd~~['L', 'l']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "L") {
		($dx, $dy, $cpX, $cpY) = ($1-$cpX, $2-$cpY, $1, $2);
	      }
	      else {
		($dx, $dy, $cpX, $cpY) = ($1, $2, $cpX+$1, $cpY+$2);
	      }

	      # округляем относительные координаты
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd~~['m','l'] && $dx && $dy) {
		$data = $data." $dx,$dy";
		$rcmd = "l";
	      }
	      elsif (!($rcmd~~['m','l']) && $dx && $dy) {
		$data = $data."l$dx,$dy";
		$rcmd = "l";
	      }
	      elsif ($rcmd ne "h" && $dx && !$dy) {
		$data = $data."h$dx";
		$rcmd = "h";
	      }
	      elsif ($rcmd eq "h" && $dx && !$dy) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dx += $1;
		$data = $data." $dx";
		$rcmd = "h";
	      }
	      elsif ($rcmd ne "v" && !$dx && $dy) {
		$data = $data."v$dy";
		$rcmd = "v";
	      }
	      elsif ($rcmd eq "v" && !$dx && $dy) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dy += $1;
		$data = $data." $dy";
		$rcmd = "v";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data if ($data);
	}

	# обрабатываем команду "horizontal-lineto": H|h x
	elsif ($cmd~~['H', 'h']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "H") {
		($dx, $cpX) = ($1-$cpX, $1);
	      }
	      else {
		($dx, $cpX) = ($1, $cpX+$1);
	      }

	      # округляем относительные координаты
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "h" && $dx) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dx += $1;
		$data = $data." $dx";
		$rcmd = "h";
	      }
	      elsif ($rcmd ne "h" && $dx) {
		$data = $data."h$dx";
		$rcmd = "h";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data if ($data);
	}

	# обрабатываем команду "vertical-lineto": V|v y
	elsif ($cmd~~['V', 'v']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "V") {
		($dy, $cpY) = ($1-$cpY, $1);
	      }
	      else {
		($dy, $cpY) = ($1, $cpY+$1);
	      }

	      # округляем относительные координаты
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "v" && $dy) {
# 		$data=~ s/($num)$// if ($data);
# 		$d=~ s/($num)$// if (!$data);
# 		$dy += $1;
		$data = $data." $dy";
		$rcmd = "v";
	      }
	      elsif ($rcmd ne "v" && $dy) {
		$data = $data."v$dy";
		$rcmd = "v";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data if ($data);
	}

	# обрабатываем команду "curveto": C|c (x1 y1 x2 y2 x y)
	elsif ($cmd~~['C', 'c']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num$cwsp?$num$cwsp?$num$cwsp?$num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$cwsp?($num)$cwsp?($num)$cwsp?($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "C") {
		($dx1, $dy1, $dx2, $dy2) = ($1-$cpX, $2-$cpY, $3-$cpX, $4-$cpY);
		($dx, $dy, $cpX, $cpY) = ($5-$cpX, $6-$cpY, $5, $6);
	      }
	      else {
		($dx1, $dy1, $dx2, $dy2) = ($1, $2, $3, $4);
		($dx, $dy, $cpX, $cpY) = ($5, $6, $cpX+$5, $cpY+$6);
	      }

	      # округляем относительные координаты
	      $dx1 = &round_num($dx1,'',$args{'dp_d'}) if ($dx1=~ /\./);
	      $dy1 = &round_num($dy1,'',$args{'dp_d'}) if ($dy1=~ /\./);
	      $dx2 = &round_num($dx2,'',$args{'dp_d'}) if ($dx2=~ /\./);
	      $dy2 = &round_num($dy2,'',$args{'dp_d'}) if ($dy2=~ /\./);
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
		  if ($rcmd eq "c") {
		    $data = $data." $dx1,$dy1 $dx2,$dy2 $dx,$dy";
		    $rcmd = "c";
		  }
		  else {
		    $data = $data."c$dx1,$dy1 $dx2,$dy2 $dx,$dy";
		    $rcmd = "c";
		  }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# обрабатываем команду "smooth-curveto": S|s (x2 y2 x y)
	elsif ($cmd~~['S', 's']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num$cwsp?$num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$cwsp?($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "S") {
		($dx2, $dy2, $dx, $dy, $cpX, $cpY) = ($1-$cpX, $2-$cpY, $3-$cpX, $4-$cpY, $3, $4);
	      }
	      else {
		($dx2, $dy2, $dx, $dy, $cpX, $cpY) = ($1, $2, $3, $4, $cpX+$3, $cpY+$4);
	      }

	      # округляем относительные координаты
	      $dx2 = &round_num($dx2,'',$args{'dp_d'}) if ($dx2=~ /\./);
	      $dy2 = &round_num($dy2,'',$args{'dp_d'}) if ($dy2=~ /\./);
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "s") {
		$data = $data." $dx2,$dy2 $dx,$dy";
		$rcmd = "s";
	      }
	      else {
		$data = $data."s$dx2,$dy2 $dx,$dy";
		$rcmd = "s";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# обрабатываем команду "quadratic-bezier-curveto": Q|q (x1 y1 x y)
	elsif ($cmd~~['Q', 'q']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num$cwsp?$num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$cwsp?($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "Q") {
		($dx1, $dy1, $dx, $dy, $cpX, $cpY) = ($1-$cpX, $2-$cpY, $3-$cpX, $4-$cpY, $3, $4);
	      }
	      else {
		($dx1, $dy1, $dx, $dy, $cpX, $cpY) = ($1, $2, $3, $4, $cpX+$3, $cpY+$4);
	      }

	      # округляем относительные координаты
	      $dx1 = &round_num($dx1,'',$args{'dp_d'}) if ($dx1=~ /\./);
	      $dy1 = &round_num($dy1,'',$args{'dp_d'}) if ($dy1=~ /\./);
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "q") {
		$data = $data." $dx1,$dy1 $dx,$dy";
		$rcmd = "q";
	      }
	      else {
		$data = $data."q$dx1,$dy1 $dx,$dy";
		$rcmd = "q";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# обрабатываем команду "smooth-quadratic-bezier-curveto": T|t (x y)
	elsif ($cmd~~['T', 't']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      if ($cmd eq "T") {
		($dx, $dy, $cpX, $cpY) = ($1-$cpX, $2-$cpY, $1, $2);
	      }
	      else {
		($dx, $dy, $cpX, $cpY) = ($1, $2, $cpX+$1, $cpY+$2);
	      }

	      # округляем относительные координаты
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "t") {
		$data = $data." $dx,$dy";
		$rcmd = "t";
	      }
	      else {
		$data = $data."t$dx,$dy";
		$rcmd = "t";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# обрабатываем команду "elliptical-arc": A|a (rx ry x-axis-rotation large-arc-flag sweep-flag x y)
	elsif ($cmd~~['A', 'a']) {
	  # берем параметр команды
	  my $param = shift @d;
	  # новые данные, которые получатся в результате обработки параметра текущей команды
	  my $data;
	  # создаем массив, содержащий пары координат текущей команды
	  my @param = split(/($num$cwsp?$num$cwsp?$num$cwsp$flag$cwsp?$flag$cwsp?$num$cwsp?$num)/, $param);

	  # обрабатываем вышеуказанный массив
	  while (@param) {
	    my $param = shift @param;

	    # если параметром является пара координат
	    if ($param=~ /^($num)$cwsp?($num)$cwsp?($num)$cwsp(0|1)$cwsp?(0|1)$cwsp?($num)$cwsp?($num)$/) {

	      # рассчитываем координаты
	      ($rx, $ry, $xar, $laf, $sf) = ($1, $2, $3, $4, $5);
	      if ($cmd eq "A") {
		($dx, $dy, $cpX, $cpY) = ($6-$cpX, $7-$cpY, $6, $7);
	      }
	      else {
		($dx, $dy, $cpX, $cpY) = ($6, $7, $cpX+$6, $cpY+$7);
	      }

	      # округляем относительные координаты
	      $rx = &round_num($rx,'',$args{'dp_d'}) if ($rx=~ /\./);
	      $ry = &round_num($ry,'',$args{'dp_d'}) if ($ry=~ /\./);
	      $xar = &round_num($xar,'',$args{'dp_att'}) if ($xar=~ /\./ && $args{'dp_att'});
	      $xar = &opt_angle($xar) if ($xar < 0 || $xar > 360);
	      $xar = 0 if ($xar == 360);
	      $dx = &round_num($dx,'',$args{'dp_d'}) if ($dx=~ /\./);
	      $dy = &round_num($dy,'',$args{'dp_d'}) if ($dy=~ /\./);

	      # прекращаем обработку данных, если радиусы дуги меньше нуля - это ошибка
	      if ($rx < 0 || $ry < 0) {
		$d = $d.$data if ($data);
		last CYCLE_D;
	      }

	      # формируем переменную $data в зависимости от $rcmd
	      if ($rcmd eq "a") {
		$data = $data." $rx,$ry $xar $laf,$sf $dx,$dy";
		$rcmd = "a";
	      }
	      else {
		$data = $data."a$rx,$ry $xar $laf,$sf $dx,$dy";
		$rcmd = "a";
	      }
	    }
	    # прекращаем обработку данных, если параметр не содержит пар координат или пробелов, разделяющих пары координат
	    elsif ($param!~ /^$cwsp?$/) {
	      $d = $d.$data if ($data);
	      last CYCLE_D;
	    }
	  }
	  $d = $d.$data;
	}

	# пропускаем пробелы и пустые значения
	elsif ($cmd=~ /^$cwsp?$/) {
	  next CYCLE_D;
	}
	# прекращаем обработку данных, если командой является любая другая буква
	else {
	  last CYCLE_D;
	}
      } # цикл CYCLE_D

      $elt->set_att($att => $d);
      &crt_att($elt,$att,"absolute coordinates converted to relative ones",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # округление всех чисел и удаление ненужных пробелов в значениях атрибутов d, если не используется преобразование абсолютных координат в относительные
    if ($att eq "d" &&
	($args{'round_numbers'} eq "yes" ||
	$args{'spf_space'} eq "delete")) {

      # создаем из $att_val массив, в котором числа будут являться отдельными элементами
      my @d = split(/($num)/, $att_val);
      # новые данные path
      my $d;

      # цикл обработки обработки данных текущего элемента path
      CYCLE_RND:
      while (@d) {

	my $data = shift @d;

	# округляем числа
	if ($args{'round_numbers'} eq "yes" &&
	    $data=~ /^$num$/ && $data=~ /\./ && $data!~ /[Ee]/) {

	  $data = &round_num($data,'',$args{'dp_d'});
	}
	# удаляем пробелы возле букв команд или прекращаем обработку данных, если буква не соответствует команде path
	elsif ($data=~ /^\s*[A-Za-z]\s*$/) {

	  last CYCLE_RND if ($data!~ /[MZLHVCSQTAmzlhvcsqta]/);
	  $data=~ s/\s+//g if ($args{'spf_space'} eq "delete" && $data=~ /\s+/);
	}
	# обрабатываем пробелы и запятые
	elsif ($args{'spf_space'} eq "delete" &&
	       $data=~ /^$cwsp$/) {
      
	  if ($data=~ /,/) {
	      $data = "," ;
	  } else {
	      $data = " ";
	  }
	}

	$d = $d.$data;
      } # CYCLE_RND

      $elt->set_att($att => $d);
      &crt_att($elt,$att,"all numbers were rounded",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # округление всех чисел и удаление ненужных пробелов в значениях атрибутов points
    if ($att eq "points" &&
	($args{'round_numbers'} eq "yes" ||
	$args{'spf_space'} eq "delete")) {

      # создаем из $att_val массив, в котором числа будут являться отдельными элементами
      my @points = split(/($num)/, $att_val);
      # новые данные path
      my $points;

      # цикл обработки обработки данных текущего элемента
      while (@points) {

	my $data = shift @points;

	# округляем числа
	if ($args{'round_numbers'} eq "yes" &&
	    $data=~ /^$num$/ && $data=~ /\./ && $data!~ /[Ee]/) {

	  $data = &round_num($data,'',$args{'dp_d'});
	}
	# обрабатываем пробелы и запятые
	elsif ($args{'spf_space'} eq "delete" &&
	       $data=~ /^$cwsp$/) {
      
	  if ($data=~ /,/) {
	    $data = "," ;
	  } else {
	    $data = " ";
	  }
	}

	$points = $points.$data;
      }

      $elt->set_att($att => $points);
      &crt_att($elt,$att,"all numbers were rounded",$i,$elt_name,$elt_id);
      next CYCLE_ATTS;
    }


    # обработка атрибутов transform, gradientTransform и patternTransform
    if ($att~~['transform','gradientTransform','patternTransform']) {

      # первоначальное значение атрибута
      my $old_att = $att_val;

      # преобразование матрицы в одну из элементарных трансформаций, если это возможно
      if ($att_val=~ /^$matrix$/) {

	# translate - matrix(1,0,0,1,x,y)
	$att_val = "translate($5,$6)" if ($1==1 && $2==0 && $3==0 && $4==1);

	# scale - matrix(kx,0,0,ky,0,0)
	$att_val = "scale($1,$4)" if ($2==0 && $3==0 && $5==0 && $6==0);

	# rotate - matrix(cos(a),sin(a),-sin(a),cos(a),0,0)
	if ($2==0 && $3==0 &&
	    $1==$4 && $5==0 && $6==0 &&
	    (&acos($1)-&asin($2))<0.01) {

	  my $angle = &asin($2);
	  $att_val = "rotate($angle)";
	}
	elsif ($2!=0 && $3!=0 && $2/$3==-1 &&
	    $1==$4 && $5==0 && $6==0 &&
	    (&acos($1)-&asin($2))<0.01) {

	  my $angle = &asin($2);
	  $att_val = "rotate($angle)";
	}

	# skewX - matrix(1,0,tg(a),1,0,0)
	if ($1==1 && $2==0 && $4==1 && $5==0 && $6==0) {

	  my $angle = &atan($3);
	  $att_val = "skewX($angle)";
	}

	# skewY - matrix(1,tg(a),0,1,0,0)
	if ($1==1 && $3==0 && $4==1 && $5==0 && $6==0) {

	  my $angle = &atan($2);
	  $att_val = "skewY($angle)";
	}
      }

      # преобразование нескольких трансформаций в одну трансформацию matrix
	$att_val = &trans_matrix($att_val) if ($args{'conc_trans'} eq "yes" && $att_val=~ /\).+\)/);

      # форматирование параметров атрибутов transform, gradientTransform и patternTransform
      # translate - перемещение
      if ($att_val=~ /^$translate$/) {

	(my $a,my $b) = ($1,$2);

	$a = &round_num($a,'',$args{'dp_d'}) if ($args{'dp_d'} && $a!~ /^$scinum$/ && $a=~ /\./);
	$b = &round_num($b,'',$args{'dp_d'}) if ($args{'dp_d'} && $b && $b!~ /^$scinum$/ && $b=~ /\./);

	$att_val = "translate($a,$b)" if ($b);
	$att_val = "translate($a)" if (!$b || $b == 0);
      }

      # scale - масштабирование
      if ($att_val=~ /^$scale$/) {

	(my $a,my $b) = ($1,$2);

	$a = &round_num($a,'',$args{'dp_att'}) if ($args{'dp_att'} && $a!~ /^$scinum$/ && $a=~ /\./);
	$b = &round_num($b,'',$args{'dp_att'}) if ($args{'dp_att'} && $b && $b!~ /^$scinum$/ && $b=~ /\./);

	$att_val = "scale($a,$b)" if ($b && $a != $b);
	$att_val = "scale($a)" if (!$b || $a == $b);
      }

      # rotate - поворот
      if ($att_val=~ /^$rotate$/) {

	(my $a,my $b,my $c) = ($1,$2,$3);

	$a = &opt_angle($a) if ($a < 0 || $a > 360);
	$a = 0 if ($a == 360);

	$a = &round_num($a,'',$args{'dp_att'}) if ($args{'dp_att'} && $a!~ /^$scinum$/ && $a=~ /\./);
	$b = &round_num($b,'',$args{'dp_d'}) if ($args{'dp_d'} && $b && $b!~ /^$scinum$/ && $b=~ /\./);
	$c = &round_num($c,'',$args{'dp_d'}) if ($args{'dp_d'} && $c && $c!~ /^$scinum$/ && $c=~ /\./);

	$att_val = "rotate($a,$b,$c)" if ($b && $c);
	$att_val = "rotate($a)" unless ($b && $c);
      }

      # skewX - наклон вдоль оси X
      if ($att_val=~ /^$skewX$/) {

	my $a = $1;

	$a = &opt_angle($a) if ($a < 0 || $a > 360);
	$a = 0 if ($a == 360);
	$a = &round_num($a,'',$args{'dp_att'}) if ($args{'dp_att'} && $a!~ /^$scinum$/ && $a=~ /\./);

	$att_val = "skewX($a)";
      }

      # skewY - наклон вдоль оси Y
      if ($att_val=~ /^$skewY$/) {

	my $a = $1;

	$a = &opt_angle($a) if ($a < 0 || $a > 360);
	$a = 0 if ($a == 360);
	$a = &round_num($a,'',$args{'dp_att'}) if ($args{'dp_att'} && $a!~ /^$scinum$/ && $a=~ /\./);

	$att_val = "skewY($a)";
      }

      # matrix - матрица
      if ($att_val=~ /^$matrix$/) {

	(my $a,my $b,my $c,my $d,my $e,my $f) = ($1,$2,$3,$4,$5,$6);

	if ($args{'dp_tr'}) {
	  $a = &round_num($a,'',$args{'dp_tr'}) if ($a!~ /^$scinum$/ && $a=~ /\./);
	  $b = &round_num($b,'',$args{'dp_tr'}) if ($b!~ /^$scinum$/ && $b=~ /\./);
	  $c = &round_num($c,'',$args{'dp_tr'}) if ($c!~ /^$scinum$/ && $c=~ /\./);
	  $d = &round_num($d,'',$args{'dp_tr'}) if ($d!~ /^$scinum$/ && $d=~ /\./);
	  $e = &round_num($e,'',$args{'dp_tr'}) if ($e!~ /^$scinum$/ && $e=~ /\./);
	  $f = &round_num($f,'',$args{'dp_tr'}) if ($f!~ /^$scinum$/ && $f=~ /\./);
	}

	$att_val = "matrix($a,$b,$c,$d,$e,$f)";
      }

      # удаление атрибута, если он задает тождественное преобразование, которое ничего не изменяет
      # matrix(1,0,0,1,0,0)
      if (&trans_matrix($att_val) eq "matrix(1,0,0,1,0,0)") {

	&del_att($elt,$att,"it specifies the identity transformation",$i,$elt_name,$elt_id);
	next CYCLE_ATTS;
      }

      # сохраняем значение атрибута, если оно было изменено
      if ("$att_val" ne "$old_att") {
	$elt->set_att($att => $att_val);
	&crt_att($elt,$att,"\"$att_val\"",$i,$elt_name,$elt_id);
      }
      next CYCLE_ATTS;
    }


    # замена ссылок на удаленные элементы
    if ($att_val =~ /^url\(#(.+)\)$/ ||
	($att eq "xlink:href" && $att_val =~ /^#(.+)$/)) {

      if (exists($comp_elts{$1})) {
	$elt->set_att($att => "url(#$comp_elts{$1})") if ($att ne "xlink:href");
	$elt->set_att($att => "#$comp_elts{$1}") if ($att eq "xlink:href");
      }
    }
  } # цикл: обработка всех атрибутов текущего элемента
    print "\n\n" if ($i != 0 && $ARGV[2] && $ARGV[2] ne "quiet");
} # цикл: обработка всех элементов файла



############################
# ЗАВЕРШИТЕЛЬНАЯ ОБРАБОТКА #
############################

print colored ("\nPOST-PROCESSING\n\n", 'bold blue underline') if ($ARGV[2] && $ARGV[2] ne "quiet");


# поиск и удаление дубликатов элементов из секции defs - второй проход
if ($args{'dupl_defs'} eq "yes" && $defs) {

  # очищаем хэш со ссылками идентичных элементов на первый по счету из них для экономии памяти
  %comp_elts = ();

  # обработка всех элементов из секции defs
  foreach my $elt ($defs->children) {

    # получаем имя элемента
    my $elt_name = $elt->name;
    # получаем id элемента
    my $elt_id = $elt->id;

    # если существует id элемента
    if ($elt_id) {

      # обрабатываем градиенты для удаления дублирующихся элементов stop
      if ($elt_name=~ /^linearGradient$|^radialGradient$/ &&
	  $elt->children('stop')) {

	my @desc_stop = ();
	foreach ($elt->children('stop')) {

	  my $stop = &desc_elt($_);

	  if ($stop~~@desc_stop) {
	    $_->delete;
	  } else {
	    push @desc_stop, $stop;
	  }
	}
      }

      # получаем описание элемента
      my $desc = &desc_elt($elt);

      # если описание элемента уже существует
      if (exists($desc_elts{$desc})) {

	# добавляем id элемента в хэш ссылок идентичных элементов, а сам элемент удаляем
	$comp_elts{$elt_id} = $desc_elts{$desc};
	$elt->delete;

	if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored (" <$elt_name", 'bold red');
	print " id=\"$elt_id\" (it's a duplicated element)\n\n";
	}
      } else {

	# если нет, то добавляем описание элемента в хэш описания элементов секции defs
	$desc_elts{$desc} = $elt_id;
      }
    }
  }

  # очищаем хэш описания элементов секции defs для экономии памяти
  %desc_elts = ();

  # глобальная замена ссылок на удаленные элементы
  foreach my $elt ($root->descendants) {
    foreach my $att ($elt->att_names) {
    my $att_val = $elt->att($att);
      if ($att_val =~ /^url\(#(.+)\)$/ ||
	  ($att eq "xlink:href" && $att_val =~ /^#(.+)$/)) {

	if (exists($comp_elts{$1})) {
	  $elt->set_att($att => "url(#$comp_elts{$1})") if ($att ne "xlink:href");
	  $elt->set_att($att => "#$comp_elts{$1}") if ($att eq "xlink:href");
	}
      }
    }
  }
}


# объединение градиентов, если на градиент существует только одна ссылка
if ($args{'singly_grads'} eq "yes" && $defs) {

  # первый проход - определяем одиночные ссылки
  foreach my $elt ($defs->get_xpath('./linearGradient[@xlink:href]'), $defs->get_xpath('./radialGradient[@xlink:href]')) {

    my $link = $elt->att('xlink:href');

    if (exists $xlinks{$link}) {
      $xlinks{$link} = 0;
    } else {
      $xlinks{$link} = 1;
    }
  }

  # второй проход - обрабатываем градиенты
  foreach my $elt ($defs->get_xpath('./linearGradient[@xlink:href]'), $defs->get_xpath('./radialGradient[@xlink:href]')) {

    my $link = substr($elt->att('xlink:href'), 1);

    # если ссылка на другой градиент не содержится в массиве внешних ссылок и этот градиент не имеет трансформации (это исключение связано с тем, что результат рендеринга таких ссылок не однозначен у Инкскейпа и Файерфокса), то объединяем два градиента в один
    if ($xlinks{"#$link"} &&
	!($link~~@out_link) &&
	$twig->elt_id($link) &&
	!($twig->elt_id($link)->att('gradientTransform'))) {

      my $elt_name = $elt->name;
      my $elt_id = $elt->id;

      if ($ARGV[2] && $ARGV[2] ne "quiet") {

	print colored (" <$elt_name", 'bold green');
	print " id=$elt_id:\n";
	print color 'bold red'; print "  <",$twig->elt_id($link)->name; print color 'reset';
	print " id=$link (it's the singly referenced gradient)\n\n";
      }

      foreach ($twig->elt_id($link)->children) {

	$_->move(last_child => $elt);
      }

      while((my $att, my $att_val) = each %{$twig->elt_id($link)->atts}) {

	if ($elt_name eq "linearGradient" &&
	    $att~~@lingrad_atts &&
	    !($att~~$rem_gratts{$elt_id}) &&
	    !(defined $elt->att($att))) {

	  $elt->set_att($att => $att_val); 
	}

	if ($elt_name eq "radialGradient" &&
	    $att~~@radgrad_atts &&
	    !($att~~$rem_gratts{$elt_id}) &&
	    !(defined $elt->att($att))) {

	  $elt->set_att($att => $att_val);
	}
      }

      $twig->elt_id($link)->delete;
      $elt->del_att('xlink:href');
    }
  }
}


# разгруппировываем группу, если элемент g не содержит атрибутов или содержит только атрибут id, который не входит в список использующихся id
if ($args{'erase_groups'} eq "yes" ||
    $args{'empty_groups'} eq "delete") {

  foreach my $elt ($root->get_xpath('//g')) {

    my $elt_id = $elt->id;

    # удаляем пустые группы
    if ($args{'empty_groups'} eq "delete") {

      # удаляем пустую группу, если она не содержит дочерних элементов
      $elt->delete unless ($elt->children);

      # обрабатываем группу, если все ее дочерние элементы являются группами
      if ($elt->children &&
	  $elt->all_children_are('g')) {

	foreach ($elt->children) {
	  # удаляем пустую дочернюю группу
	  $_->delete unless ($_->children);
	}
	# удаляем основную группу, если она стала пустой
	$elt->delete unless ($elt->children);
      }
    }


    # разгруппировываем группы, если их родительским элементом не является элемент switch
    if ($args{'erase_groups'} eq "yes" &&
	!($elt->parent('switch')) &&
	$elt->children) {

      # если группа содержит только атрибут id, который не содержится в списке использующихся id и содержит цифру в случае использования защиты id, состоящих только из букв
      if ($elt->att_nb == 1 && $elt_id && !($elt_id ~~ @ref_id) &&
	  ($args{'protect_id'} ne "yes" || ($args{'protect_id'} eq "yes" && $elt_id=~/\d/))) {

	$elt->erase;
      }
      # если группа не имеет атрибутов
      elsif ($elt->has_no_atts) {

	$elt->erase;
      }
    }
  }
}


# сортировка элементов в секции defs
if ($args{'sort_defs'} eq "yes" && 
    $root->children('defs')) {

  foreach my $defs_elt (@defs_elts) {
    if ($defs_elt eq "linearGradient") {
      foreach ($defs->get_xpath('//linearGradient[not @xlink:href]')) {
	$_->move(last_child => $defs);
      }
      foreach ($defs->get_xpath('//linearGradient[@xlink:href]')) {
	$_->move(last_child => $defs);
      }
    }
    elsif ($defs_elt eq "radialGradient") {
      foreach ($defs->get_xpath('//radialGradient[not @xlink:href]')) {
	$_->move(last_child => $defs);
      }
      foreach ($defs->get_xpath('//radialGradient[@xlink:href]')) {
	$_->move(last_child => $defs);
      }
    }
    elsif ($defs_elt eq "filter") {
      foreach ($defs->get_xpath('//filter[not @height and not @width]')) {
	$_->move(last_child => $defs);
      }
      foreach ($defs->get_xpath('//filter[@height or @width]')) {
	$_->move(last_child => $defs);
      }
    }
    else {
      foreach ($defs->get_xpath("//$defs_elt")) {
	$_->move(last_child => $defs);
      }
    }
  }
}

# преобразовываем SVG атрибуты в свойства атрибута style
if ($args{'style_prop'} ne "yes") {

  # обрабатываем все элементы файла
  foreach my $elt ($root->descendants_or_self) {

    my $style_att;

    # обрабатываем все атрибуты текущего элемента
    while ((my $att, my $att_val) = each %{$elt->atts}) {
      # если атрибут можно представить в виде свойства атрибута style
      if ($att~~@style_atts) {
	# формируем атрибут style
	if ($style_att) {
	  $style_att = $style_att.";$att:$att_val";
	} else {
	  $style_att = "$att:$att_val";
	}
	# удаляем SVG атрибут
	$elt->del_att($att);
      }
    }
    # сохраняем атрибут style
    $elt->set_att('style' => $style_att) if ($style_att);
  }
}

# определяем конечный размер файла
my $size_final = length($twig->sprint);

# определяем конечное количество элементов в файле
my $elts_final = scalar($root->descendants_or_self);

# определяем конечное количество атрибутов в файле
my $atts_final = 0;

foreach my $elt ($root->descendants_or_self) {
  $atts_final+=($elt->att_nb);
}


if ($ARGV[2] && $ARGV[2] ne "quiet") {
  # вывод конечного размера файла
  print colored (" The final file size is $size_final bytes\n", 'bold');
  # вывод конечного количества элементов
  print colored (" The final number of elements is $elts_final\n", 'bold');
  # вывод конечного количества атрибутов
  print colored (" The final number of attributes is $atts_final\n\n", 'bold');
} else {
  print " The final file size is $size_final bytes\n";
  print " The final number of elements is $elts_final\n";
  print " The final number of attributes is $atts_final\n\n";
}




#########
# ОТЧЕТ #
#########

print colored ("\nREPORT\n\n", 'bold blue underline') if ($ARGV[2] && $ARGV[2] ne "quiet");

# размер оптимизированного файла по отношению к оригинальному в процентах
my $size_diff = sprintf("%.2f", $size_final/$size_initial*100);
my $elts_diff = $elts_initial-$elts_final;
my $atts_diff = $atts_initial-$atts_final;

if ($ARGV[2] && $ARGV[2] ne "quiet") {
  # вывод нового размера файла (в процентах)
  print colored (" The new file size is $size_diff%\n", 'bold');
  # вывод количества удаленых элементов
  print colored (" The number of removed elements is $elts_diff\n", 'bold');
  # вывод количества удаленых атрибутов
  print colored (" The number of removed attributes is $atts_diff\n\n", 'bold');
} else {
  print " The new file size is $size_diff%\n";
  print " The number of removed elements is $elts_diff\n";
  print " The number of removed attributes is $atts_diff\n\n";
}


####################
# СОХРАНЕНИЕ ФАЙЛА #
####################

# устанавливаем стиль размещения элементов
$twig->set_pretty_print($args{'pretty_print'});

# устанавливаем число отступов перед тэгами
$twig->set_indent(' ' x $args{'indent'});

# устанавливаем стиль пустых тэгов
$twig->set_empty_tag_style($args{'empty_tags'});

# устанавливаем стиль кавычек ('double' или 'single')
$twig->set_quote($args{'quote'});

# сохраняем результаты в файл
$twig->print_to_file($ARGV[0]);

# очищаем память
$twig->purge;

# форматирование в стиле Inkscape
# exec "bash /home/andrew/inkscapepp.sh $ARGV[0]";

exit;
__END__

# переименовывает и сжимает файл svg в svgz (удаление svg не нужно)
# gzip -S z /home/kubuntu/Development/OutputSVG/folder-old.svg

# сохраняет оригинальный файл
# gzip -c folder-old.svg > folder-old.svgz

# максимальные параметры оптимизации у scour
# time scour -i input.svg -o output.svg --enable-id-stripping --enable-comment-stripping --remove-metadata --strip-xml-prolog --enable-viewboxing --indent=none