---
layout: post
title: Optimize Elasticsearch Result
author: Tesla Lee
date: 2018-05-02 00:00:00 +0800
categories: [elasticsearch]
---

### 问题
现在的 ES 查询有不少问题，

1. 结果太老，没有显示较新的几个结果
2. 查询出的结果与预期的不太匹配

比如在文章中查询**锦囊**这个关键词，结果很不准确。

现在我使用的查询是这样的：

```json
{
  "query": {
    "bool": {
      "should": [
        {
          "term": {
            "title": {
              "value": "锦囊",
              "boost": 9
            }
          }
        },
        {
          "query_string": {
            "default_field": "title",
            "query": "title: 锦囊",
            "boost": 19
          }
        },
        {
          "wildcard": {
            "title.raw": {
              "value": "*锦囊*",
              "boost": 29
            }
          }
        },
        {
          "term": {
            "summary": {
              "value": "锦囊",
              "boost": 8
            }
          }
        },
        {
          "query_string": {
            "default_field": "summary",
            "query": "summary: 锦囊",
            "boost": 18
          }
        },
        {
          "wildcard": {
            "summary.raw": {
              "value": "*锦囊*",
              "boost": 28
            }
          }
        },
        {
          "term": {
            "content": {
              "value": "锦囊",
              "boost": 7
            }
          }
        },
        {
          "query_string": {
            "default_field": "content",
            "query": "content: 锦囊",
            "boost": 17
          }
        },
        {
          "wildcard": {
            "content.raw": {
              "value": "*锦囊*",
              "boost": 27
            }
          }
        }
      ]
    }
  }
}
```

现在的索引结构是这样的
```json
{
  "state": "open",
  "settings": {
    ...
  },
  "mappings": {
    "post-haoyc": {
      "dynamic": "false",
      "properties": {
        "summary": {
          "analyzer": "ik",
          "type": "string",
          "fields": {
            "raw": {
              "index": "not_analyzed",
              "type": "string"
            }
          }
        },
        "title": {
          "analyzer": "ik",
          "type": "string",
          "fields": {
            "raw": {
              "index": "not_analyzed",
              "type": "string"
            }
          }
        },
        "content": {
          "analyzer": "ik",
          "type": "string",
          "fields": {
            "raw": {
              "index": "not_analyzed",
              "type": "string"
            }
          }
        }
      }
    }
  }
}
```

现在的查询结果是这样的
```json
"hits": {
    "total": 118,
    "max_score": 1.6573191,
    "hits": [
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "1780",
        "_score": 1.6573191,
        "_source": {
          "updated_at": "2017-01-03T19:24:21.000+08:00",
          "created_at": "2017-01-03T11:44:23.000+08:00",
          "title": "外汇收紧不用方，给你个防贬值锦囊"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "2122",
        "_score": 1.4486072,
        "_source": {
          "updated_at": "2017-04-19T17:03:23.107+08:00",
          "created_at": "2017-04-19T17:03:23.107+08:00",
          "title": "世界这么乱，李嘉诚都去买黄金了"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "2732",
        "_score": 1.4202242,
        "_source": {
          "updated_at": "2018-02-08T16:16:01.033+08:00",
          "created_at": "2018-02-08T16:16:01.033+08:00",
          "title": "财神到！送你理财锦囊一整套！"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "1908",
        "_score": 1.4002953,
        "_source": {
          "updated_at": "2017-02-20T15:19:20.478+08:00",
          "created_at": "2017-02-20T15:19:20.478+08:00",
          "title": "2017家庭理财小锦囊，你值得拥有"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "2416",
        "_score": 1.3986247,
        "_source": {
          "updated_at": "2017-08-25T12:48:56.489+08:00",
          "created_at": "2017-08-25T12:48:56.489+08:00",
          "title": "2017下半年理财锦囊（链接原始版）"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "1326",
        "_score": 1.3717031,
        "_source": {
          "updated_at": "2016-09-21T19:27:05.000+08:00",
          "created_at": "2016-09-21T11:53:53.000+08:00",
          "title": "亲测有效！不离婚也能拿到一线城市买房资格"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "1687",
        "_score": 1.2302854,
        "_source": {
          "updated_at": "2016-12-12T17:16:56.000+08:00",
          "created_at": "2016-12-12T15:22:13.000+08:00",
          "title": "股市暴跌，人民币暴跌，送你一个救命锦囊"
        }
      },
      {
        "_index": "posts-haoyc",
        "_type": "post-haoyc",
        "_id": "2144",
        "_score": 0.66505533,
        "_source": {
          "updated_at": "2017-04-25T16:40:43.083+08:00",
          "created_at": "2017-04-25T16:40:43.083+08:00",
          "title": "马云说未来30年大部分人很倒霉，今天我懂了"
        }
      }
    ]
  }
```
