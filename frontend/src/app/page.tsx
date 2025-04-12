'use client'

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ToastAction } from "@/components/ui/toast"
import { useToast } from "@/hooks/use-toast"
import { zodResolver } from "@hookform/resolvers/zod"
import { useState } from "react"
import { useForm } from "react-hook-form"
import { z } from "zod"

const formSchema = z.object({
  email: z.string().email("请输入有效的邮箱地址"),
})

type FormValues = z.infer<typeof formSchema>

export default function Home() {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { toast } = useToast()
  
  const { register, handleSubmit, formState: { errors }, reset } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
  })
  
  const onSubmit = async (data: FormValues) => {
    setIsSubmitting(true)
    
    try {
      const response = await fetch('/api/v1/waitlist', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      })
      
      if (response.ok) {
        toast({
          title: "成功！",
          description: "您已成功加入我们的等待名单。",
          variant: "default",
        })
        reset()
      } else {
        throw new Error('加入等待名单失败')
      }
    } catch (error) {
      toast({
        title: "出现错误",
        description: "加入等待名单失败，请稍后重试。",
        variant: "destructive",
        action: <ToastAction altText="重试">重试</ToastAction>,
      })
    } finally {
      setIsSubmitting(false)
    }
  }
  
  return (
    <main className="min-h-screen flex items-center justify-center bg-gradient-to-b from-sky-50 to-slate-100 p-4">
      <Card className="max-w-md w-full border-sky-100 shadow-lg">
        <CardHeader>
          <CardTitle className="text-2xl font-bold text-sky-900">欢迎来到 Quest</CardTitle>
          <CardDescription>加入我们的等待名单，获取早期访问资格</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="grid w-full items-center gap-4">
              <div className="flex flex-col space-y-1.5">
                <Label htmlFor="email">邮箱</Label>
                <Input 
                  id="email" 
                  placeholder="请输入您的邮箱" 
                  {...register("email")}
                />
                {errors.email && (
                  <p className="text-sm text-red-500">{String(errors.email.message)}</p>
                )}
              </div>
            </div>
            <div className="mt-6">
              <Button 
                type="submit" 
                className="w-full bg-sky-600 hover:bg-sky-700"
                disabled={isSubmitting}
              >
                {isSubmitting ? "正在提交..." : "加入等待名单"}
              </Button>
            </div>
          </form>
        </CardContent>
        <CardFooter className="flex justify-center text-sm text-slate-500">
          我们承诺不会发送垃圾邮件！
        </CardFooter>
      </Card>
    </main>
  )
} 