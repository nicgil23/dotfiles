#!/bin/bash
waybar &
pkill -9 waybar && waybar &
pkill -9 swaync && swaync &
