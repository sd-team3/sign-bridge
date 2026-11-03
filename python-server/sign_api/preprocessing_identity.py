import ast
import hashlib
import inspect
import json


def fingerprint():
    from .body_features import encode, mirror, Extractor, SCHEMA, SIZE, POSE_IDS
    from .hand_tracking import HandTracker, candidates, recover_candidates, expected_missing, VERSION
    from .sign_model import normalize_hands, HAND_POINTS, FEATURE_SIZE
    source=[]
    for item in [encode,mirror,Extractor,HandTracker,candidates,recover_candidates,expected_missing,normalize_hands]:
        tree=ast.parse(inspect.getsource(item))
        for node in ast.walk(tree):
            if isinstance(node,(ast.FunctionDef,ast.AsyncFunctionDef,ast.ClassDef)) and node.body:
                first=node.body[0]
                if isinstance(first,ast.Expr) and isinstance(first.value,ast.Constant) and isinstance(first.value.value,str):
                    node.body=node.body[1:]
        source.append(ast.dump(tree,include_attributes=False))
    payload=json.dumps(dict(source=source,schema=SCHEMA,size=SIZE,pose_ids=POSE_IDS,
        hand_points=HAND_POINTS,feature_size=FEATURE_SIZE,version=VERSION),sort_keys=True).encode()
    return hashlib.sha256(payload).hexdigest()
