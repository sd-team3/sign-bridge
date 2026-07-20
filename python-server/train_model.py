# -*- coding: utf-8 -*-
"""
CLI에서 수동으로 학습을 돌리고 싶을 때 쓰는 진입점.
실제 로직은 training.py에 있고, FastAPI의 POST /model/train도 같은 로직을 사용한다.
"""

from training import train

if __name__ == "__main__":
    train()
