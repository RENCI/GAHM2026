---
layout: default
title: Derivation and Implementation
parent: Source Documents
nav_order: 2
permalink: /source-documents/derivation-and-implementation/
source_document: documentation/Derivation_and_Implementation.docx
source_sha256: "edd7d7e78ab7f61439ccb4edbad0bf073239f722854ad7f9fe4590d4e1fba1da"
---

> Converted from the [source DOCX](https://github.com/RENCI/GAHM2026/blob/main/documentation/Derivation_and_Implementation.docx).

# GAHM2026 Derivation and Implementation

Rick Luettich 8/1/2025, rev 8/4/2026

## 1. Derivation (adapted from J. Gao, 2018)

Consider the radial profile of atmospheric pressure in a tropical cyclone can be expressed as a hyperbolic function of the deviation of the pressure from an ambient, far-field pressure Schloemer (1954), Holland (1980).

$$\begin{array}{r}
P(r) = P_{c} + \left( P_{n} - P_{c} \right)e^{- \frac{A}{r^{B_{g}}}}\tag{1}
\end{array}$$

$P$(r) is the atmospheric pressure (mb) at radius $r$,$\ P_{c}$ is the minimum central pressure (mb) in the eye of the cyclone, $P_{n}$ is the ambient, far-field pressure, and $e$ is the exponential function. $A$ and $B_{g}$ are scaling parameters.

Substituting this expression into the gradient wind balance in radial coordinates yields an equation for the tangential gradient wind at the top of the boundary layer:

$$\begin{array}{r}
V_{g}(r) = \sqrt{\frac{AB_{g}\left( P_{n} - P_{c} \right)e^{- \frac{A}{r^{B_{g}}}}}{\rho_{air}r^{B_{g}}} + \left( \frac{rf}{2} \right)^{2}} - \left( \frac{rf}{2} \right)\tag{2}
\end{array}$$

where $V_{g}(r)$ is the gradient wind (m/s) at radius $r$ (m) at the top of the boundary layer, $\rho_{air}$ is the density of air (kg/m^3^), and $f$ is the Coriolis parameter (s^-1^).

Setting $V_{g}\left( {r = R}_{mw} \right) = V_{\max}$, where $R_{mw}$ (m) is the radius to maximum winds and $V_{\max}$ (m/s) is the maximum wind speed at the top of the boundary layer, and rearranging terms, Eq (2) can be rewritten as:

$$\begin{array}{r}
{% raw %}
\frac{AB_{g}\left( P_{n} - P_{c} \right)}{\rho_{air}} = e^{\frac{A}{{R_{mw}}^{B_{g}}}}{R_{mw}}^{B_{g}}\left\{ \left\lbrack V_{\max} + \ \left( \frac{R_{mw}f}{2} \right) \right\rbrack^{2} - \ \left( \frac{R_{mw}f}{2} \right)^{2} \right\}\tag{3}
{% endraw %}
\end{array}$$

Letting $A \equiv \varphi\ {R_{mw}}^{B_{g}}$ and $R_{o} \equiv \frac{V_{\max}}{R_{mw}f}$ and rearranging yields

$$\begin{array}{r}
\frac{AB_{g}\left( P_{n} - P_{c} \right)}{\rho_{air}} = e^{\varphi}{R_{mw}}^{B_{g}}\left\lbrack {V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right) \right\rbrack\tag{4}
\end{array}$$

substituting Eq (4) into Eq (2) yields:

$$\begin{array}{r}
{% raw %}
V_{g}(r) = \sqrt{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack} + \left( \frac{rf}{2} \right)^{2}} - \left( \frac{rf}{2} \right)\tag{5}
{% endraw %}
\end{array}$$

{% raw %}
A further constraint can be introduced by requiring that $\frac{{dV}_{g}(r)}{dr} = 0$ at $r = R_{mw}$. To differentiate Eq (5), first rearrange the equation as:
{% endraw %}

$$\begin{array}{r}
\left( V_{g}(r)\  + \frac{rf}{2} \right)^{2} = {V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack} + \left( \frac{rf}{2} \right)^{2}
\end{array}$$

Taking the derivatives of both sides (<https://www.derivative-calculator.net>):

$$\begin{array}{r}
{% raw %}
2\left( V_{g}(r)\  + \frac{rf}{2} \right)\left( \frac{{dV}_{g}(r)}{dr} + \frac{f}{2} \right) = \frac{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\left\lbrack \varphi\left( \frac{R_{mw}}{r} \right)^{B_{g}} - 1 \right\rbrack\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack}}{r} + \frac{rf^{2}}{2}\#
{% endraw %}
\end{array}$$

{% raw %}
Setting $\frac{{dV}_{g}(r)}{dr} = 0,\ V_{g}(r) = V_{\max}\ @\ r = R_{mw}$ yields:
{% endraw %}

$$\begin{array}{r}
{% raw %}
V_{\max}f\  + \frac{R_{mw}f^{2}}{2} = \frac{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\lbrack\varphi - 1\rbrack}{R_{mw}} + \frac{R_{mw}f^{2}}{2}\tag{6}
{% endraw %}
\end{array}$$

which can be simplified to:

$$R_{mw}f = V_{\max}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\lbrack\varphi - 1\rbrack\ \ \ \ \ \ \ \ \ \ or\ \ \ \ \ \ \ \ \ \ \frac{1}{\left( 1 + R_{o} \right)} = B_{g}\lbrack\varphi - 1\rbrack$$

and therefore:

$$\begin{array}{r}
B_{g} = \frac{1}{\left( 1 + R_{o} \right)(\varphi - 1)}\ \ \ \ \ \ \ or\ \ \ \ \ \ \ \varphi = 1 + \frac{1}{B_{g}\left( 1 + R_{o} \right)}\tag{7}
\end{array}$$

Eliminating $\varphi$, Eq. (4) can be re-written as:

$$\begin{array}{r}
B_{g} = e^{1 + \frac{1}{B_{g}\left( 1 + R_{o} \right)}}\frac{\left\lbrack {V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right) \right\rbrack}{\frac{\left( P_{n} - P_{c} \right)}{\rho_{air}}} - \frac{1}{\left( 1 + R_{o} \right)}\tag{8}
\end{array}$$

and Eq. (5) can be re-written as:

$$\begin{array}{r}
{% raw %}
V_{g}(r) = \sqrt{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\left( 1 + \frac{1}{B_{g}\left( 1 + R_{o} \right)} \right)\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack} + \left( \frac{rf}{2} \right)^{2}} - \left( \frac{rf}{2} \right)\tag{9}
{% endraw %}
\end{array}$$

Rewriting $R_{o}$

$$\begin{array}{r}
R_{o} \equiv \frac{V_{\max}}{R_{mw}f} = \frac{V_{\max}}{rf}\frac{r}{R_{mw}} = \ R_{r}\ \frac{r}{R_{mw}} = \ R_{r}\ c^{- 1}\ \ \ where\ \ \ R_{r} \equiv \frac{V_{\max}}{rf}\ \ \ and\ \ \ \ c = \frac{R_{mw}}{r}\tag{10}
\end{array}$$

allows Eqs (8) and (9) to be written as:

$$\begin{array}{r}
B_{g} = e^{1 + \frac{1}{B_{g}\left( 1 + R_{r}c^{- 1} \right)}}\frac{\left\lbrack {V_{\max}}^{2}\left( 1 + c\ {R_{r}}^{- 1} \right) \right\rbrack}{\frac{\left( P_{n} - P_{c} \right)}{\rho}} - \frac{1}{\left( 1 + R_{r}c^{- 1} \right)}\tag{11}
\end{array}$$

$$\begin{array}{r}
{% raw %}
V_{g}(r) = \sqrt{{V_{\max}}^{2}\left( 1 + {cR_{r}}^{- 1} \right)c^{B_{g}}e^{\left( 1 + \frac{1}{B_{g}\left( 1 + R_{r}c^{- 1} \right)} \right)\left\lbrack 1 - c^{B_{g}} \right\rbrack} + \left( \frac{rf}{2} \right)^{2}} - \left( \frac{rf}{2} \right)\tag{12}
{% endraw %}
\end{array}$$

For given values of $\frac{\left( P_{n} - P_{c} \right)}{\rho}$, $V_{\max}$, and $V_{g}(r)$, Eqs. (6) -(8) or alternatively Eqs (9) and (10) can be solved recursively to determine values of $B_{g}$ and $R_{mw}$, respectively. The latter equations involve only the unknowns $B_{g}$ and $c$, including the constraint that $0 < c \leq 1$.

Finally, Eqs (6) and (9) can be written in terms of the original Holland (1980) $B$ parameter,

{% raw %}
$$B \equiv \ \frac{{V_{\max}}^{2}e}{\frac{\left( P_{n} - P_{c} \right)}{\rho_{air}}}$$
{% endraw %}

yielding:

$$\begin{array}{r}
B_{g} = Be^{\frac{1}{B_{g}\left( 1 + R_{o} \right)}}\left( 1 + {R_{o}}^{- 1} \right) - \frac{1}{\left( 1 + R_{o} \right)}\ \tag{13}
\end{array}$$

and

$$\begin{array}{r}
B_{g} = Be^{\frac{1}{B_{g}\left( 1 + R_{r}c^{- 1} \right)}}\left( 1 + c\ {R_{r}}^{- 1} \right) - \frac{1}{\left( 1 + R_{r}c^{- 1} \right)}\ \tag{14}
\end{array}$$

making it clear that $B_{g} \rightarrow B\ \ \ as\ \ R_{o} = R_{r}\ c^{- 1}\  \rightarrow \ \infty\ \$

Dividing Eq (13) by *B* the resulting equation can be plotted, Figure 1:

![A close-up of a diagram AI-generated content may be incorrect.]({{ '/assets/source-documents/derivation-and-implementation/media/image1.png' | relative_url }}){width="3.410416666666667in" height="1.7673611111111112in"}

Figure 1. Profiles of $\frac{B_{g}}{B}$ from GAHM with respect to $\log_{10}R_{o}$ for different $B\$values. (Figure 2.1 from Gao 2018).

Also, Eq (9) or (12) can be written in a non-dimensional form:

$$\begin{array}{r}
{% raw %}
\frac{V_{g}(r)}{V_{\max}} = \sqrt{\left( 1 + {R_{o}}^{- 1} \right)\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\left( 1 + \frac{1}{B_{g}\left( 1 + R_{o} \right)} \right)\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack} + \left( \frac{r}{R_{mw}} \right)^{2}\left( \frac{1}{{2R}_{o}} \right)^{2}} - \left( \frac{r}{R_{mw}} \right)\left( \frac{1}{{2R}_{o}} \right)\tag{15}
{% endraw %}
\end{array}$$

$$\begin{array}{r}
{% raw %}
\frac{V_{g}(r)}{V_{\max}} = \sqrt{\left( 1 + {cR_{r}}^{- 1} \right)c^{B_{g}}e^{\left( 1 + \frac{1}{B_{g}\left( 1 + R_{r}c^{- 1} \right)} \right)\left\lbrack 1 - c^{B_{g}} \right\rbrack} + \left( \frac{1}{{2R}_{r}} \right)^{2}} - \left( \frac{1}{{2R}_{r}} \right)\tag{16}
{% endraw %}
\end{array}$$

and plotted, Figure 2:

![A group of graphs showing different colors AI-generated content may be incorrect.]({{ '/assets/source-documents/derivation-and-implementation/media/image2.png' | relative_url }}){width="6.17in" height="4.39in"}

Figure 2. Normalized gradient wind profiles for the original Holland (1980) model and GAHM for $\log_{10}R_{o} = 0,\ 1,\ and\ 2$ (or correspondingly $R_{o}\  = 1,\ 10,\ and\ 100$) and *B* $B_{g}?$ varying from 0.5 to 2. (Figure 2.3 from Gao 2018).

As a check, setting $r = R_{mw}$ in Eq (15) yields

$$\begin{array}{r}
{% raw %}
\frac{V_{g}(r)}{V_{\max}} = \sqrt{\left( 1 + {R_{o}}^{- 1} \right) + \left( \frac{1}{{2R}_{o}} \right)^{2}} - \left( \frac{1}{{2R}_{o}} \right)
{% endraw %}
\end{array}$$

$$\begin{array}{r}
{% raw %}
\frac{V_{g}(r)}{V_{\max}} = \frac{1}{2R_{o}}\sqrt{4R_{o}\left( R_{o} + 1 \right) + 1} - \left( \frac{1}{{2R}_{o}} \right)
{% endraw %}
\end{array}$$

$$\begin{array}{r}
{% raw %}
\frac{V_{g}(r)}{V_{\max}} = \frac{1}{2R_{o}}\sqrt{\left( 2R_{o} + 1 \right)^{2}} - \left( \frac{1}{{2R}_{o}} \right) = 1
{% endraw %}
\end{array}$$

It is helpful to use GAHM to compute the pressure deficit, from Eq (1).

$\begin{array}{r}
P(r) - P_{n}\  = \left( P_{n} - P_{c} \right)\left( e^{- \frac{A}{r^{B_{g}}}} - 1 \right) = \left( P_{n} - P_{c} \right)\left( e^{- {\varphi\left( \frac{R_{mw}}{r} \right)}^{B_{g}}} - 1 \right)\tag{17}
\end{array}$

## 2. Implementation

It is assumed that $V_{g}(r),\ \ V_{\max}$ in GAHM2026 are tangential, 10 min average vortex velocities at the top of the boundary layer. These are also equal to the 10-min average vortex speed since it is assumed that the vortex has only tangential velocity at the top of the boundary layer.

Data sources for GAHM2026 are typically comprised of values for the eye position (lon, lat), the minimum central pressure (mb), $P_{c}$, the ambient pressure (mb), $P_{n}$, (note, in the ADCIRC version of GAHM this is assumed to be 1013 mb), the 1-min sustained maximum total windspeed at 10m height above ground (kt), $V_{max\_ 1\_ 10}$, and the radial distances (nautical miles) from the TC eye to the 1-min sustained, 64, 50, and 34 knot total windspeed isotachs in the NE, SE, SW, and NW quadrants. Depending on the data source, the radial distance to the radius to maximum winds (nautical miles), $R_{mw}$, may also be provided.

To utilize this information in GAHM2026, the total wind velocities must be converted into 10-min average, tangential velocities at the top of the boundary layer. This is done utilizing the following assumptions and notation.

1.  [Define values that satisfy the GAHM2026 equations:]{.underline} It is assumed that the GAHM2026 equations apply to 10-minuite averaged "vortex fields" at the top of the tropical cyclone boundary layer (and thus above the influence of friction with the land/water surface). These are designated $P_{c\_ vor\_ 10\_ tbl},V_{vor\_ 10\_ tbl}$ $\$where the $vor$ subscript denotes "vortex field", the initial \_10 subscript denotes 10-min average, and the latter \_tbl subscript denotes a height equal to the top of the boundary layer.

2.  [Convert 1-min sustained wind velocities to 10-min averaged values]{.underline}: It is assumed that the maximum, $V_{\max}$, and the 64, 50 and 34 knot isotach input wind speeds are 1-min sustained values and that these can be converted to 10-min averaged values using a conversion factor *one2ten* = 0.89 (e.g., Kruk et al, 2010), i.e.,

$$V_{max\_ 10} = \ {one2ten*V}_{max\_ 1}$$

where the initial \_1 subscript denotes a 1-minute sustained value. It is assumed that the input pressure values are 10-min averages and need no conversion. Note, *one2ten* can be specified in the GAHM2026 configuration file.

3.  [Convert wind velocities from 10 m above ground to the top of the boundary layer]{.underline}: It is assumed that all wind velocities at the top of the boundary layer and 10 m above ground are related via a boundary layer factor, *BLF* = 0.9 ([Powell ...]{.mark} ), i.e.,

$$V_{\_ 10\_ 10} = \ {BLF*V}_{\_ 10\_ tbl}$$

and that in the northern hemisphere the vortex component of the velocity experiences a counter clockwise turning angle (clockwise in the southern hemisphere) defined as:

> Turning angle (deg) ${= 10*r/R}_{mw}\ \ if\ r \leq R_{mw}$
>
> Turning angle (deg) ${= 10 + 75*(r/R}_{mw} - 1)\ \ if\ R_{mw} < r \leq 1.2*R_{mw}$=
>
> Turning angle (deg) $= 25\ \ if\ 1.2*R_{mw} < r$

Note, *BLF* can be specified in the GAHM2026 configuration file.

4.  [Decompose the total pressure field and total wind velocity field into "vortex fields" and "environmental fields"]{.underline}: It is assumed that the input wind velocity and pressure fields are total fields that represent the sums of "vortex fields", $P_{c\_ vor\_ 10\_ 10},V_{vor\_ 1\_ 10}$, and "environmental fields", $P_{c\_ env\_ 10\_ 10},V_{env\_ 10\_ 10}$, reflecting larger scale spatial processes. Due to the linear scaling between 10 m elevation and the top of the boundary layer, this separation is applicable either at a height of 10 m above ground, i.e., $V_{max\_ 10\_ 10} = \ V_{maxvor\_ 10\_ 10} + \ V_{env\_ 10\_ 10}$, or at the top of the boundary layer, i.e., ., $V_{max\_ tbl} = \ V_{vor\_ 10\_ tbl} + \ V_{env\_ 10\_ tbl}$.

5.  The "environmental fields", $P_{c\_ env\_ 10},V_{env\_ 10}$, may either be specified as spatially varying inputs, e.g., if extracted from large scale gridded model data, or inferred from the storm's translation velocity, $V_{trans}$. In the latter case, two options are supported:

    a.  ADCIRC assumes $V_{env\_ 1\_ 10\ } = 1.5*\ {V_{trans}}^{0.63}$ (for $V_{trans}$ in knots) or $V_{env\_ 1\_ 10\ } = 1.5*\ {V_{trans}}^{0.63}*{0.51444}^{0.37}$ (for $V_{trans}$ in m/s) and $V_{env\_ 1\_ 10\ }$ varies with radial distance from the eye following the same relationship as $V_{g}(r)$, Eq. (15) or (16). In GAHM2026 it is assumed that an environmental velocity derived from the translation velocity better reflects 10-min averaged value than a 1-min sustained value and therefore that $V_{env\_ 10\_ 10\ } = 1.5*\ {V_{trans}}^{0.63}$ or $V_{env\_ 10\_ 10\ } = 1.5*\ {V_{trans}}^{0.63}*{0.51444}^{0.37}$.

    b.  Lin and Chavas (2012) analyzed H\*Wind snapshots and concluded that a spatially constant $V_{env\_ xx\_ 10\ } = 0.55*V_{trans}$ where $V_{env\_ xx\_ 10}$ is rotated 20 degrees counterclockwise from $V_{trans}$, is better supported than the value assumed in ADCIRC. In GAHM2026 it is assumed that $V_{env\_ 10\_ 10\ } = 0.6*V_{trans}$.where $V_{env\_ 10\_ 10}$ is rotated 20 degrees counterclockwise from $V_{trans}$.

To proceed,

1.  Compute the 10 min averaged, maximum, tangential vortex velocity at 10 m elevation, ${VMax}_{vor\_ 10\_ 10},$ from the input total maximum velocity magnitude, $\left| V_{max\_ 1\_ 10\ } \right|$ and the environmental velocity, $V_{env\_ 10\_ 10\ }$. The total maximum velocity occurs when the environmental velocity and the maximum, tangential vortex velocity are aligned, i.e.,

$$V_{max\_ 10\_ 10} = one2ten*\left| V_{\max\_ 1\_ 10} \right|\ *V_{envuv\_ 10\_ 10}$$

where $V_{envuv\_ 10\_ 10}$ is the unit vector in the direction of $V_{env\_ 10\_ 10}$. Because of this alignment, the magnitude of the maximum, tangential vortex velocity is equal to the difference between the magnitudes of the input total maximum velocity and the environmental velocity.

$$\left| V_{maxvor\_ 10\_ 10} \right| = \left| V_{\max\_ 10\_ 10} \right| - \ \left| V_{env\_ 10\_ 10} \right|$$

The maximum vortex velocity at the top of the boundary layer is thus equal to

$$V_{maxvor\_ 10\_ tbl} = \ \left( \frac{\left| V_{maxvor\_ 10\_ 10} \right|}{BLF} \right)*V_{voruv\_ tbl}$$

where the vortex velocity unit vector at the top of the boundary layer, $V_{voruv\_ tbl}$, is tangent to the circular vortex and directed ccw in the northern hemisphere (cw in the southern hemisphere) at any location. The location around the vortex where $V_{max\_ 10\_ 10}$ and $V_{max\_ 10\_ tbl}$ occur will be different due to the assumed turning angle between 10 m and the top of the boundary layer.

2.  Check the magnitude of $V_{maxvor\_ 10\_ tbl}$. It is assumed that the gradient wind balance is valid only if $\left| V_{maxvor\_ 10\_ tbl} \right| \geq \left| V_{maxvor\_ 10\_ tbl} \right|_{\min}\$. If this condition is violated, GAHM should not be used. A reasonable value for $\left| V_{maxvor\_ 10\_ tbl} \right|_{\min}$ is assumed to be 20 kts, although this value can be set in the GAHM2026 configuration file.

3.  Assuming the availability of isotach total wind magnitudes (i.e., $\left| {VQuad}_{\_ 1\_ 10} \right| = \$`<!-- -->`{=html}64, 50, 34 kts at specified radial distances from the eye in the NE, SE, SW and NW quadrants), these need to be converted to 10-min, tangential vortex velocities at the top of the boundary layer, ${VQuad}_{vor\_ 10\_ tbl}$. These are written as:

$${VQuad}_{vor\_ 10\_ tbl} = \ \left| {VQuad}_{vor\_ 10\_ tbl} \right|*\ {VQuad}_{voruv\_ tbl}\ $$

where the unit vector in each quadrant, ${VQuad}_{voruv\_ tbl}$, is assumed to be tangent to a circle at the midpoint of that quadrant and directed ccw in the northern hemisphere (cw in the southern hemisphere). For example, in the northern hemisphere the unit vector for the NE quadrant would point NW (315 deg cw from North). Given this, the quadrant vortex velocity at 10 m height is:

$${VQuad}_{vor\_ 10\_ 10} = \ BLF*\left| {VQuad}_{vor\_ 10\_ tbl} \right|*{VQuad}_{voruv\_ 10}$$

where the quadrant unit vector at 10 m, ${VQuad}_{voruv\_ 10}$, is equal to the value at the top of the boundary layer plus any assumed turning angle (see above).

Taking the isotach value as the input magnitude of the total wind velocity, this can be expressed as the magnitude of the sum of the vortex and environmental components,

$$one2ten*\left| {VQuad}_{\_ 1\_ 10} \right| = \left| {VQuad}_{\_ 10\_ 10} \right| = \ \left| {VQuad}_{vor\_ 10\_ 10} + \ V_{env\_ 10\_ 10} \right|\ $$

which can be solved for the unknown $\left| {VQuad}_{vor\_ 10\_ 10} \right|$.

Two consistency checks are performed to ensure this relationship can yield a physically valid solution.

a.  The first check assumes that fitting the gradient wind balance to the isotach is valid only if $\left| {VQuad}_{vor\_ 10\_ tbl} \right| \geq \left| {VQuad}_{vor\_ 10\_ tbl} \right|_{\min}$. Setting $\left| {VQuad}_{vor\_ 10\_ tbl} \right| = \left| {VQuad}_{vor\_ 10\_ tbl} \right|_{\min}\$ , the above equation can be evaluated to determine a minimum acceptable value of $\left| {VQuad}_{1\_ 10} \right|_{\min}$. If $\left| {VQuad}_{1\_ 10} \right|{< \left| {VQuad}_{1\_ 10} \right|}_{\min}$, the isotach should not be used to determine $R_{mw}$, rather $R_{mw}$ is determined from the next higher isotach in the quadrant. A reasonable value for $\left| {VQuad}_{vor\_ 10\_ tbl} \right|_{\min}$ is assumed to be 5 kts, although this value can be set in the GAHM2026 configuration file.

b.  The second checks assumes that $\left| {VQuad}_{vor\_ 10\_ tbl} \right| \leq \left| V_{maxvor\_ 10\_ tbl} \right|$. Setting $\left| {VQuad}_{vor\_ 10\_ tbl} \right| = \left| V_{maxvor\_ 10\_ tbl} \right|\$, the above equation can be evaluated to determine a maximum acceptable value of $\left| {VQuad}_{1\_ 10} \right|_{\max}$. If this is violated, $R_{mw}$ = *RQuad* and $\left| {VQuad}_{vor\_ 10\_ tbl} \right| = \left| V_{maxvor\_ 10\_ tbl} \right|$.

If both of these conditions are satisfied, $\left| {VQuad}_{vor\_ 10\_ 10} \right|$ is solved for by squaring both sides and expanding the right-hand side to yield:

$\left| {VQuad}_{vor\_ 10\_ 10} \right|^{2} + 2\left| {VQuad}_{vor\_ 10\_ 10} \right|\left| V_{env\_ 10\_ 10} \right|\left( {VQuad}_{voruv\_ 10\_ 10}\  \bullet V_{envuv\_ 10\_ 10} \right)\$

$+ \left| V_{env\_ 10\_ 10} \right|^{2} - \left| {VQuad}_{\_ 10\_ 10} \right|^{2} = 0$

which can be solved for $\left| {VQuad}_{vor\_ 10\_ 10} \right|$ using the quadratic formula. (See also Appendix B)

A special variant arises for the ADCIRC implementation of GAHM, because the radial profile of $\left| V_{env\_ 10\_ 10} \right|$ is assumed to match the radial profile of the vortex gradient wind. Thus at the radial location where $\left| {VQuad}_{\_ 10\_ 10} \right|$ has been specified, the environmental velocity can be expressed as:

$$\left| V_{env\_ 10\_ 10} \right| = \ \left| {V^{*}}_{env\_ 10\_ 10} \right|*\frac{\left| {VQuad}_{vor\_ 10\_ 10} \right|}{\left| {VMax}_{vor\_ 10\_ 10} \right|}$$

where ${V^{*}}_{env\_ 10\_ 10}$ is the environmental velocity at $r = R_{mw}$. In this case the quadratic equation can be written as:

{% raw %}
$\left| {VQuad}_{vor\_ 10\_ 10} \right|^{2}\left\{ 1 + 2\left( {VQuad}_{voruv\_ 10\_ 10}\  \bullet V_{envuv\_ 10\_ 10} \right)\frac{\left| {V^{*}}_{env\_ 10\_ 10} \right|}{\left| {VMax}_{vor\_ 10\_ 10} \right|} + \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \frac{\left| {V^{*}}_{env\_ 10\_ 10} \right|^{2}}{\left| {VMax}_{vor\_ 10\_ 10} \right|^{2}} \right\}\$ $- \left| {VQuad}_{{}_{10_{10}}} \right|^{2} = 0$
{% endraw %}

$$\left| {VQuad}_{vor\_ 10\_ 10} \right|^{2}\left| {VQuad}_{voruv\_ 10\_ 10} + \left( V_{envuv\_ 10\_ 10} \right)\frac{\left| {V^{*}}_{env\_ 10\_ 10} \right|}{\left| {VMax}_{vor\_ 10\_ 10} \right|} \right|^{2}\ \ \  - \left| {VQuad}_{\_ 10\_ 10} \right|^{2} = 0$$

$$\left| {VQuad}_{vor\_ 10\_ 10} \right|\  = \frac{\left| {VQuad}_{\_ 10\_ 10} \right|}{\left| {VQuad}_{voruv\_ 10\_ 10} + \left( V_{envuv\_ 10\_ 10} \right)\frac{\left| {V^{*}}_{env\_ 10\_ 10} \right|}{\left| {VMax}_{vor\_ 10\_ 10} \right|} \right|}$$

In contrast to the general case, this variant imposes no explicit constraint on the relative size of $\left| {VQuad}_{\_ 10\_ 10} \right|$ and $\left| {V^{*}}_{env\_ 10\_ 10} \right|$.

## 3. GAHM2026 default conditions / assumptions

These are checked / set in GAHM2026_consistency.m

If no isotach distances exist in a quadrant, $R_{mw}$ for that quadrant is determined as the average value from the quadrant(s) having valid values. In this case $B_{g}$ is determined from Eq. (13).

isotach indices are 1=34kt, 2=50kt, 3=64kt, 4=00kt

1\. Check whether Holland 1980 B value falls within specified limits

If Bmin \<= B \<= Bmax GAHM.flag_B=1

if B \< Bmin, B is reset = Bmin and GAHM.flag_B=0

if B \> Bmax, B is reset = Bmax and GAHM.flag_B=2

Note:

B is input via the GAHM datastructure

Bmin, Bmax are set in the configuration file

2\. Check if any isotach (*34kt*, *50kt*, *64kt*) distances are present in any quadrant in the track file for the current time.

If this condition is not met, GAHM.flag(1:4,1:4) = 0. Rmw in all quadrants = Rmw read in from the track file. Bg, A, phi computed from GAHM2026.

3\. Check that SVorMax_10_tbl \>= SVorMax_10_tblmin - this ensures that the vortex maximum speed (input maximum speed minus the environmental speed), moved to the top of the boundary layer, is strong enough (\>20 kts?) to use GAHM to compute Rmw. SVorMax_10_tblmin is set in the configuration file.

If this condition is not met, GAHM.flag(1:4,1:3)=2, GAHM.flag(1:4,4)=0, Rmw in all quadrants = Rmw read in from track file. Bg, A, phi computed from GAHM2026.

4\. Check if an isotach distance is present in the track file for a specific quadrant, isotach pair.

If not, GAHM.flag(q,i)=0;

5\. SVorQuad_10_tbl \> SVorQuad_10_tblmin - this ensures that the vortex isotach speeds in each quadrant (input isotach velocity minus the environmental velocity), moved to the top of the boundary layer, is strong enough (\>5 kts?) to use GAHM to compute Rmw. SVorQuad_10_tblmin is set in the configuration file. This is checked for each quadrant, isotach pair.

If this condition is not met, then GAHM_flag(q,i)=3. Rmw is copied from surrounding isotachs (e.g., next higher isotach in quadrant) and Bg, A, phi computed from GAHM2026.

6\. SVorMax_10_10 \>= SVorQuad_10_10(q,i) - this ensures that the vortex isotach speeds in each quadrant are \< or = the vortex maximum speeded. This is checked for each quadrant, isotach pair assuming 10 and 25 deg ccw turning angles from the tbl to *10m.*

If this condition is not met for both turning angles, GAHM_flag(q,i)=4. In this case assume Rmw = RQuad, SVorQuad_10_10(q,i)=SVorMax_10_10. Bg, A phi are computed using GAHM2026. If the condition is not met for only one of the turning angles, GAHM_flag(q,i)=5. An intermediate turning angle is estimated and use to determine Rmw, Bg, A, phi using GAHM2026.

## 4. Blending with gridded large-scale fields

## 5. List of Input required for GAHM2026

This is incomplete, remains a work in progress.

Vmax -- maximum wind speed, assumed to represent the vector sum of the maximum vortex wind velocity and the environmental wind velocity. In IBTracs file, ATCF file, fort.22 file, this is assumed to be in kts. GAHM2024 requires it to be converted to m/s.

RQuad -- radial distances to 34, 50, 64 kt isotach in the 4 quadrants. In IBTracs file, ATCF file, fort.22 file, this is assumed to be in nautical miles. GAHM2026 requires it to be converted to meters.

Environmental velocity @ location of Vmax and at location of RQuad values. GAHM2026 requires this to be in m/s. Options for determining the environmental velocity are generating it from the translation velocity or reading it in from a gridded source

Environmental velocity type -- specifying to use ADCIRC version, Lin and Chavas (2012) version, or read in from file version. envtype=1, 2, 3, respectively.

Rmax -- default value for Rmax (in meters). This is only used if there are no RQuad values.

Pn-Pc -- central pressure deficit in Newtons / m\^2 = 100\*mb

$\rho_{air}$ - density of air (kg/m^3^), default 1.2, set in the configuration file

$B_{\min},\ \ B_{\max}$- minimum and maximum allowable values of the Holland (1980) B parameter, default 0.5, 2.5, set in the configuration file

BLF -- scaling factor reducing the wind velocity at the top of the boundary layer to the value at 10 meters, range 0.75 -- 0.9, default 0.9, set in the configuration file

one2tenF -- scaling factor reducing the wind speed from a 1-min sustained value to a 10-min average value, default 0.89, set in the configuration file.

Pn = Pback

## 6. References

Gao, J., 2018. PhD Dissertation, Dept of Marine Sciences, University of North Carolina at Chapel Hill,

Holland, G.J., 1980. An Analytic Model of the Wind and Pressure Profiles in Hurricanes, Monthly Weather Review, v106, 1212-1218.

Kurk, M.C., K.R. Knapp, D.H. Levinson, 2010. A Technique for Combining Global Tropical Cyclone Best Track Data, J Atmos Ocean Tech, v27, pgs 680-692, DOI: 10.1175/2009JTECHA1267.1 -- (One2ten=0.88, IBTracs)

Lin, N., and D. Chavas, 2012. On hurricane parametric wind and applications in storm surge modeling, J. Geophysical Res., Atmospheres, <https://doi.org/10.1029/2011JD017126>

Note, I think there is a more recent N. Lin reference (Gori ?) that uses a factor of 0.6 rather than 0.55 recommended in L&C 2012

Powell, M. ...... reference for 0.9 BLF

Schloemer, R.W. 1954. Analysis and synthesis of hurricane wind patterns of Lake Okechobee, FL, Hydromet Rep. 31, 49pp.

## Appendix A - Alternative derivation of $\frac{\mathbf{dV}_{\mathbf{g}}\left( \mathbf{r} \right)}{\mathbf{dr}}$

Differentiating Eq (5), (<https://www.derivative-calculator.net>)

$$\begin{array}{r}
{% raw %}
\frac{{dV}_{g}(r)}{dr} = \frac{\frac{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\left\lbrack \varphi\left( \frac{R_{mw}}{r} \right)^{B_{g}} - 1 \right\rbrack\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack}}{r} + \frac{rf^{2}}{2}}{2\sqrt{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack} + \left( \frac{rf}{2} \right)^{2}}} - \frac{f}{2}\#
{% endraw %}
\end{array}$$

Substituting Eq (5) in the denominator

$$\begin{array}{r}
{% raw %}
\frac{{dV}_{g}(r)}{dr} = \frac{\frac{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\left\lbrack \varphi\left( \frac{R_{mw}}{r} \right)^{B_{g}} - 1 \right\rbrack\left( \frac{R_{mw}}{r} \right)^{B_{g}}e^{\varphi\left\lbrack 1 - \left( \frac{R_{mw}}{r} \right)^{B_{g}} \right\rbrack}}{r} + \frac{rf^{2}}{2}}{2\left( V_{g}(r)\  + \frac{rf}{2} \right)} - \frac{f}{2}\#
{% endraw %}
\end{array}$$

{% raw %}
Setting $\frac{{dV}_{g}(r)}{dr} = 0,\ V_{g}(r) = V_{\max}\ @\ r = R_{mw}$ yields:
{% endraw %}

$$\begin{array}{r}
{% raw %}
fV_{\max}\  + \frac{R_{mw}f^{2}}{2} = \frac{{V_{\max}}^{2}\left( 1 + {R_{o}}^{- 1} \right)B_{g}\lbrack\varphi - 1\rbrack}{R_{mw}} + \frac{{R_{mw}f}^{2}}{2}\#
{% endraw %}
\end{array}$$

which is identical to Eq (6).

## Appendix B -- Restrictions on the Solution for $\left| {VQuad}_{\_ 10\_ 10} \right|$

*I believe these are automatically satisfied so long as the two consistency checks discussed in the main text are satisfied. When confirmed this appendix can be eliminated.*

$\left| {VQuad}_{vor\_ 10\_ 10} \right|^{2} + 2\left| {VQuad}_{vor\_ 10\_ 10} \right|\left| V_{env\_ 10\_ 10} \right|\left( {VQuad}_{voruv\_ 10\_ 10}\  \bullet V_{envuv\_ 10\_ 10} \right)\$

$+ \left| V_{env\_ 10\_ 10} \right|^{2} - \left| {VQuad}_{\_ 10\_ 10} \right|^{2} = 0$

which can be solved using the quadratic formula with the coefficients:

$\ a = 1$

$b = 2\left| V_{env\_ 10\_ 10} \right|\left( {VQuad}_{voruv\_ 10\_ 10}\  \bullet V_{envuv\_ 10\_ 10} \right)$

$c = \$ $\left| V_{env\_ 10\_ 10} \right|^{2} - \left| {VQuad}_{\_ 10\_ 10} \right|^{2}$

This places a lower bound on $\left| {VQuad}_{\_ 10\_ 10} \right|$ (or equivalently an upper bound on $\left| V_{env\_ 10\_ 10} \right|$) to ensure that $\left| {VQuad}_{vor\_ 10\_ 10} \right| > 0.$

There are several cases that can occur:

I.  If c\<0, the term under sqrt \> 0 and the sqrt will be greater than b. In this case the sum of the (+) sqrt and (-b) is guaranteed to be greater than 0, regardless of the sign of b.

II. If c=0, then sqrt = \|b\|. The (+) sum of this term and b will be greater than or equal to zero, regardless of the sign of b.

III. If c \> 0, then the sqrt will in all cases be less than b and in some locations around the vortex it will be imaginary (e.g., in locations where the environmental and vortex velocities approach orthogonality, causing the dot product of their unit vectors and b to approach zero.) This will lead to unphysical negative (if b \> 0) or imaginary (regardless of the sign of b) magnitudes for $\left| {VQuad}_{\_ 10\_ 10} \right|$.

> The details for Case iii depend on the spatial structure of $V_{env\_ 10\_ 10}$.
>
> Iii a. if $V_{env\_ 10\_ 10}$ has a uniform direction, as assumed in ADCIRC/ASWIP or Lin & Chavas (2012), then $\left| {VQuad}_{\_ 10\_ 10} \right| \geq \ \left| V_{env\_ 10\_ 10} \right|$ to ensure a viable solution around the full vortex. Since GAHM is only fit along the four radial lines that bisect the four quadrants, the negative case is more likely to occur than the imaginary case. If $V_{env\_ 10\_ 10}$ varies in space, as assumed in ADCIRC/ASWIP, and the distance to the specified isotach varies from quadrant to quadrant, the relationship between the environmental and quadrant velocity magnitudes may also vary from quadrant to quadrant.
>
> iiib. In the more general case where the direction and magnitude of $V_{env\_ 10\_ 10}$ vary in space, it appears there is no choice than to evaluate the relationship and adjust accordingly in each quadrant.
>
> If the environmental velocity varies slowly across the vortex, Case iii is most likely to occur for the 34 kt isotach and therefore the consequences of any adjustment imposed on the solution will extend beyond that isotach.
>
> It is not possible to fit the GAHM equations to a case where $\left| {VQuad}_{vor\_ 10\_ 10} \right| = 0$; therefore any adjustment made in response to Case iii, must result in result in $\left| {VQuad}_{vor\_ 10\_ 10} \right| > \ 0$. Adjusting either the environmental or quadrant velocities ends up determining the value of ${VQuad}_{vor\_ 10\_ 10}$. If the environmental velocity is adjusted, this must be carried throughout the calculations, including when GAHM is evaluated. If the quadrant velocity is adjusted (which is functionally equivalent to adjusting ${VQuad}_{vor\_ 10\_ 10}$ if the environmental velocity is not modified), then GAHM will not recover the quadrant velocity. In any case, the resulting value of ${VQuad}_{vor\_ 10\_ 10}$ will directly affect$R_{mw}$ and $B_{g}$ obtained from GAHM2024. It appears that a small value of ${VQuad}_{vor\_ 10\_ 10}$ results in an unreasonably small (outlier) value for $R_{mw}$.

The previous checks ensured that $\left| {VQuad}_{vor\_ 10\_ 10} \right| > 0$. It is also necessary to check that $\left| {VQuad}_{vor\_ 10\_ 10} \right| \leq \left| {VMax}_{vor\_ 10\_ 10} \right|$. If this is not the case a further adjustment must be made. Setting $\left| {VMax}_{vor\_ 10\_ 10} \right| = \left| {VQuad}_{vor\_ 10\_ 10} \right|$ while maintaining the environmental velocity, raises the total maximum velocity in the storm and ensures that $R_{mw} = \$distance to the specified isotach in the specified quadrant. Alternatively, since\
$\left| {VMax}_{vor\_ 10\_ 10} \right| = \left| V_{\max\_ 10\_ 10} \right| - \ \left| V_{env\_ 10\_ 10} \right|$, the magnitude of the environmental velocity could be reduced until $\left| {VQuad}_{vor\_ 10\_ 10} \right| = \left| {VMax}_{vor\_ 10\_ 10} \right|$. This requires the adjusted environmental velocity to be carried throughout all of the GAHM calculations and again ensures that $R_{mw} = \$distance to the specified isotach in the specified quadrant.
