# Gateway Policies

This directory stores API Gateway policies for Big-Bang cutover and stabilization.

## Objectives
- isolate faults at gateway level
- enforce route timeout/retry/rate-limit defaults
- block unsafe write routes during cutover windows
