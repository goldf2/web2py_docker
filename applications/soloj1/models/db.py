# -*- coding: utf-8 -*-

from gluon.tools import Auth
from gluon import DAL, Field, IS_NOT_EMPTY

db = DAL('sqlite://storage.sqlite', migrate=True)

auth = Auth(db)
auth.define_tables(username=True, signature=False)

db.define_table('post',
    Field('title', 'string', length=255, required=True),
    Field('content', 'text', required=True),
    Field('created_at', 'datetime', default=request.now),
    Field('user_id', 'reference auth_user', default=auth.user_id),
    format='%(title)s'
)

db.post.title.requires = IS_NOT_EMPTY()
db.post.content.requires = IS_NOT_EMPTY()
