---
layout: default
title: GAHM Derivation
nav_order: 3
permalink: /gahm-derivation/
---

# GAHM derivation

This concise derivation follows Rick Luettich's August 4, 2026 revision, adapted from Gao (2018). The [complete
derivation and implementation PDF]({{ '/assets/GAHM2026_derivation_implementation.pdf' | relative_url }}) provides
the detailed implementation, default assumptions, blending discussion, restrictions, figures, and appendices.

Let `r` be radial distance from the cyclone center, `P(r)` atmospheric pressure, `P_c` minimum central pressure,
and `P_n` ambient far-field pressure. The Holland pressure profile is

$$
P(r) = P_c + (P_n-P_c)\exp\left(-\frac{A}{r^{B_g}}\right),
\qquad A = \varphi R_{mw}^{B_g},
$$

where `A` and `B_g` are scaling parameters, `\varphi` is the generalized shape factor, and `R_{mw}` is the radius
of maximum winds. Here and below, `e` is the base of the natural logarithm.

Let `V_g(r)` be tangential gradient wind at the top of the boundary layer, `\rho_{air}` air density, and `f` the
Coriolis parameter. Radial gradient-wind balance gives

$$
V_g(r) = \sqrt{
\frac{A B_g(P_n-P_c)\exp\left(-A/r^{B_g}\right)}{\rho_{air}r^{B_g}}
+ \left(\frac{rf}{2}\right)^2
} - \frac{rf}{2}.
$$

Define `V_{\max}=V_g(R_{mw})` and the Rossby number

$$
R_o = \frac{V_{\max}}{R_{mw}f}.
$$

Applying the maximum-wind constraint at `R_{mw}` yields

$$
\frac{A B_g(P_n-P_c)}{\rho_{air}}
= e^{\varphi}R_{mw}^{B_g}V_{\max}^2\left(1+R_o^{-1}\right).
$$

The additional condition `dV_g/dr=0` at `r=R_{mw}` gives the generalized shape relation

$$
\varphi = 1 + \frac{1}{B_g(1+R_o)}.
$$

Eliminating `\varphi` produces the implicit equation

$$
B_g =
\exp\left(1+\frac{1}{B_g(1+R_o)}\right)
\frac{V_{\max}^2\left(1+R_o^{-1}\right)}{(P_n-P_c)/\rho_{air}}
- \frac{1}{1+R_o}.
$$

For an observed isotach `V_g(r)` at known `r`, this equation and the wind profile below are solved recursively for
`B_g` and `R_{mw}` (equivalently, for `B_g` and `c=R_{mw}/r`, with `0<c<=1`).

Substitution of the shape relation gives the final radial gradient-wind profile:

$$
V_g(r) = \sqrt{
V_{\max}^2\left(1+R_o^{-1}\right)
\left(\frac{R_{mw}}{r}\right)^{B_g}
\exp\left[
\left(1+\frac{1}{B_g(1+R_o)}\right)
\left(1-\left(\frac{R_{mw}}{r}\right)^{B_g}\right)
\right]
+ \left(\frac{rf}{2}\right)^2
} - \frac{rf}{2}.
$$

The corresponding pressure-deficit profile is

$$
P(r)-P_n = (P_n-P_c)
\left\{
\exp\left[-\varphi\left(\frac{R_{mw}}{r}\right)^{B_g}\right]-1
\right\}.
$$

Finally, as Coriolis effects vanish (`R_o\to\infty`), the generalized parameter approaches the original Holland
limit:

$$
B_g \longrightarrow \frac{eV_{\max}^2}{(P_n-P_c)/\rho_{air}}.
$$
